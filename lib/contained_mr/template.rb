require 'json'
require 'rubygems'  # For tar operations.
require 'yaml'

require 'docker'
require 'zip'

# A template is used to spawn multiple Map-Reduce jobs.
class ContainedMr::Template
  attr_reader :name_prefix, :item_count, :image_id

  # Sets up the template and builds its Docker base image.
  #
  # @param {String} name_prefix prepended to Docker objects, for identification
  #   purposes
  # @param {String} id the job's unique identifier
  # @param {String} zip_io IO implementation that produces the template .zip
  def initialize(name_prefix, id, zip_io)
    @name_prefix = name_prefix
    @id = id
    @image_id = nil
    @definition = nil
    @item_count = nil

    tar_buffer = StringIO.new
    process_zip zip_io, tar_buffer
    tar_buffer.rewind
    build_image tar_buffer
  end

  # Tears down the template's state.
  #
  # This removes the template's base Docker image.
  def destroy!
    unless @image_id.nil?
      image = Docker::Image.get @image_id
      image.remove
      @image_id = nil
    end
  end

  # Computes the Dockerfile used to build a job's mapper image.
  #
  # @return {String} the Dockerfile
  def mapper_dockerfile
    job_dockerfile @definition['mapper'] || {}, 'input'
  end

  # Computes the Dockerfile used to build a job's reducer image.
  #
  # @return {String} the Dockerfile
  def reducer_dockerfile
    job_dockerfile @definition['reducer'] || {}, '.'
  end

  # @return {String} tag applied to the template's base Docker image
  def image_tag
    "#{@name_prefix}/base.#{@id}"
  end

  # Computes the environment variables to be set in a mapper container.
  #
  # @param {Number} i the mapper number
  # @return {Array<String>} environment variables to be set in the mapper
  def mapper_env(i)
    [ "ITEM=#{i}", "ITEMS=#{@item_count.to_s}" ]
  end

  # Computes the environment variables to be set in the reducer container.
  #
  # @return {Array<String>} environment variables to be set in the mapper
  def reducer_env
    [ "ITEMS=#{@item_count.to_s}" ]
  end

  # @return {String} the map output's path in the mapper Docker container
  def mapper_output_path
    (@definition['mapper'] || {})['output'] || '/output'
  end

  # @return {String} the reducer output's path in the reducer Docker container
  def reducer_output_path
    (@definition['reducer'] || {})['output'] || '/output'
  end

  # @private common code from mapper_dockerfile and reducer_dockerfile
  def job_dockerfile(job_definition, input_source)
    <<DOCKER_END
FROM #{@image_id}
COPY #{input_source} #{job_definition['input'] || '/input'}
WORKDIR #{job_definition['chdir'] || '/'}
ENTRYPOINT #{JSON.dump(job_definition['cmd'] || ['/bin/sh'])}
DOCKER_END
  end
  private :job_dockerfile

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

  # Reads the template's definition, using data at the given path.
  #
  # @param {IO} yaml_io IO implementation that produces the .yaml file
  #   containing the definition
  def read_definition(yaml_io)
    @definition = YAML.load yaml_io.read

    @item_count = @definition['items'] || 1
  end
  private :read_definition

  # Builds the template's Docker image, using data at the given path.
  #
  # @param {IO} tar_io IO implementation that produces the image's .tar file
  def build_image(tar_io)
    image = Docker::Image.build_from_tar tar_io, t: image_tag
    @image_id = image.id
  end
  private :build_image
end
