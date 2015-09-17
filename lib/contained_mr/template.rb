require 'json'
require 'rubygems'  # For tar operations.
require 'yaml'

require 'docker'
require 'zip'

# A template is used to spawn multiple Map-Reduce jobs.
class ContainedMr::Template
  include ContainedMr::TemplateLogic

  # Sets up the template and builds its Docker base image.
  #
  # @param {String} name_prefix prepended to Docker objects, for identification
  #   purposes
  # @param {String} id the template's unique identifier
  # @param {String} zip_io IO implementation that produces the template .zip
  def initialize(name_prefix, id, zip_io)
    @name_prefix = name_prefix
    @id = id
    @image_id = nil
    @item_count = nil
    @_definition = nil

    tar_buffer = StringIO.new
    process_zip zip_io, tar_buffer
    tar_buffer.rewind
    build_image tar_buffer
  end

  # Tears down the template's state.
  #
  # This removes the template's base Docker image.
  #
  # @return {ContainedMr::Template} self
  def destroy!
    unless @image_id.nil?
      # HACK(pwnall): Trick docker-api into issuing a DELETE request by tag.
      image = Docker::Image.new Docker.connection, 'id' => image_tag
      image.remove
      @image_id = nil
    end
    self
  end

  # The class used by {ContainedMr::TemplateLogic#create_job}.
  #
  # @return {Class} always {ContainedMr::Job}
  def job_class
    ContainedMr::Job
  end

  # Reads the template .zip and parses the definition.
  #
  # @param {IO} zip_io IO implementation that produces the .zip file
  # @param {IO} tar_io IO implementation that will receive the .tar file
  def process_zip(zip_io, tar_io)
    Gem::Package::TarWriter.new tar_io do |tar|
      # TODO(pwnall): zip_io.read -> zip_io after rubyzip releases 1.1.8
      Zip::File.open_buffer zip_io.read do |zip|
        zip.each do |zip_entry|
          file_name = zip_entry.name
          if zip_entry.directory?
            tar.mkdir file_name, 0755
          elsif zip_entry.file?
            if file_name == 'mapreduced.yml'
              read_definition zip_entry.get_input_stream
              next
            end
            tar.add_file file_name, 0644 do |tar_file_io|
              IO.copy_stream zip_entry.get_input_stream, tar_file_io
            end
          end
        end
      end
    end
  end
  private :process_zip

  # Builds the template's Docker image, using data at the given path.
  #
  # @param {IO} tar_io IO implementation that produces the image's .tar file
  def build_image(tar_io)
    image = Docker::Image.build_from_tar tar_io, t: image_tag
    @image_id = image.id
  end
  private :build_image
end
