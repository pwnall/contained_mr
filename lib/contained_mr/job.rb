require 'json'
require 'rubygems'  # For tar operations.
require 'stringio'
require 'yaml'

require 'docker'

# A map-reduce job.
class ContainedMr::Job
  attr_reader :id, :item_count, :mapper_image_id, :reducer_image_id

  # Sets up the job.
  #
  # @param {Template} template data used to spawn this job
  # @param {String} id the job's unique ID
  # @param {Hash<String, Object>} json_options job options, extracted from JSON
  def initialize(template, id, json_options)
    @id = id
    @template = template
    @name_prefix = template.name_prefix
    @item_count = template.item_count

    @mapper_image_id = nil
    @reducer_image_id = nil

    @mappers = Array.new @item_count
    @reducer = nil
    @mapper_options = nil
    @reducer_options = nil
    parse_options json_options
  end

  # Tears down the job's state.
  #
  # This removes the job's containers, as well as the mapper and reducer Docker
  # images, if they still exist.
  def destroy!
    @mappers.each do |runner|
      next if runner.nil? or runner.container_id.nil?
      container = Docker::Container.get runner.container_id
      container.delete force: true
    end

    unless @reducer.nil? or @reducer.container_id.nil?
      container = Docker::Container.get @reducer.container_id
      container.delete force: true
    end

    unless @mapper_image_id.nil?
      # HACK(pwnall): Trick docker-api into issuing a DELETE request by tag.
      image = Docker::Image.new Docker.connection, 'id' => mapper_image_tag
      image.remove
      @mapper_image_id = nil
    end

    unless @reducer_image_id.nil?
      # HACK(pwnall): Trick docker-api into issuing a DELETE request by tag.
      image = Docker::Image.new Docker.connection, 'id' => reducer_image_tag
      image.remove
      @reducer_image_id = nil
    end
  end

  # Returns the runner used for a mapper.
  #
  # @param {Number} i the mapper number
  # @return {ContainedMr::Runner} the runner used for the given mapper; nil if
  #   the given mapper was not started
  def mapper_runner(i)
    @mappers[i - 1]
  end

  # Returns the runner used for the reducer.
  #
  # @return {ContainedMr::Runner} the runner used for reducer; nil if the
  #   reducer was not started
  def reducer_runner
    @reducer
  end

  # Builds the Docker image used to run this job's mappers.
  #
  # @param {String} mapper_input data passed to the mappers
  # @return {String} the newly built Docker image's ID
  def build_mapper_image(mapper_input)
    tar_io = mapper_tar_context mapper_input
    image = Docker::Image.build_from_tar tar_io, t: mapper_image_tag
    @mapper_image_id = image.id
  end

  # Builds the Docker image used to run this job's reducer.
  #
  # @return {String} the newly built Docker image's ID
  def build_reducer_image
    tar_io = reducer_tar_context
    image = Docker::Image.build_from_tar tar_io, t: reducer_image_tag
    @reducer_image_id = image.id
  end

  # Runs one of the job's mappers.
  #
  # @param {Number} i the mapper to run
  # @return {ContainedMr::Runner} the runner used by the mapper
  def run_mapper(i)
    mapper = ContainedMr::Runner.new mapper_container_options(i),
        @mapper_options[:wait_time], @template.mapper_output_path
    @mappers[i - 1] = mapper
    mapper.perform
  end

  # Runs one the job's reducer.
  #
  # @return {ContainedMr::Runner} the runner used by the reducer
  def run_reducer
    reducer = ContainedMr::Runner.new reducer_container_options,
        @reducer_options[:wait_time], @template.reducer_output_path
    @reducer = reducer
    @reducer.perform
  end

  # @return {String} tag applied to the Docker image used by the job's mappers
  def mapper_image_tag
    "#{@name_prefix}/mapper.#{@id}"
  end

  # @return {String} tag applied to the Docker image used by the job's reducers
  def reducer_image_tag
    "#{@name_prefix}/reducer.#{@id}"
  end

  # @return {Hash<String, Object>} params used to create a mapper container
  def mapper_container_options(i)
    ulimits = @mapper_options[:ulimits].map do |k, v|
      { "Name" => k.to_s, "Soft" => v, "Hard" => v }
    end

    {
      'name' => "#{@name_prefix}_mapper.#{@id}.#{i}",
      'Image' => @mapper_image_id,
      'Hostname' => "#{i}.mapper", 'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => @name_prefix },
      'Env' => @template.mapper_env(i), 'Ulimits' => ulimits,
      'NetworkDisabled' => true, 'ExposedPorts' => {},
    }
  end

  # @return {Hash<String, Object>} params used to create a reducer container
  def reducer_container_options
    ulimits = @reducer_options[:ulimits].map do |k, v|
      { "Name" => k.to_s, "Soft" => v, "Hard" => v }
    end

    {
      'name' => "#{@name_prefix}_reducer.#{@id}",
      'Image' => @reducer_image_id,
      'Hostname' => 'reducer', 'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => @name_prefix },
      'Env' => @template.reducer_env, 'Ulimits' => ulimits,
      'NetworkDisabled' => true, 'ExposedPorts' => {},
    }
  end

  # Reads in JSON options and sets defaults.
  def parse_options(json_options)
    mapper = json_options['mapper'] || {}
    mapper_ulimits = mapper['ulimits'] || {}
    @mapper_options = {
      wait_time: mapper['wait_time'] || 60,
      ulimits: {
        cpu: mapper_ulimits['cpu'] || 60,  # seconds
        rss: mapper_ulimits['rss'] || 500_000,  # pages
      }
    }

    reducer = json_options['reducer'] || {}
    reducer_ulimits = reducer['ulimits'] || {}
    @reducer_options = {
      wait_time: reducer['wait_time'] || 60,
      ulimits: {
        cpu: reducer_ulimits['cpu'] || 60,
        rss: reducer_ulimits['rss'] || 500_000,
      }
    }
  end
  private :parse_options

  # Builds the .tar context used to create the mapper's Docker image.
  #
  # @param {String} mapper_input data passed to the mappers
  # @return {IO} an IO implementation that sources the .tar data
  def mapper_tar_context(mapper_input)
    tar_buffer = StringIO.new
    Gem::Package::TarWriter.new tar_buffer do |tar|
      tar.add_file 'Dockerfile', 0644 do |docker_io|
        docker_io.write @template.mapper_dockerfile
      end
      tar.add_file 'input', 0644 do |input_io|
        input_io.write mapper_input
      end
    end
    tar_buffer.rewind
    tar_buffer
  end
  private :mapper_tar_context

  # Builds the .tar context used to create the mapper's Docker image.
  #
  # @return {IO} an IO implementation that sources the .tar file
  def reducer_tar_context
    tar_buffer = StringIO.new
    Gem::Package::TarWriter.new tar_buffer do |tar|
      tar.add_file 'Dockerfile', 0644 do |docker_io|
        docker_io.write @template.reducer_dockerfile
      end
      @mappers.each_with_index do |mapper, index|
        i = index + 1

        if mapper.output
          tar.add_file "#{i}.out", 0644 do |io|
            io.write mapper.output
          end
        end
        tar.add_file("#{i}.stdout", 0644) { |io| io.write mapper.stdout }
        tar.add_file("#{i}.stderr", 0644) { |io| io.write mapper.stderr }

        status = {
          ran_for: mapper.ran_for,
          exit_code: mapper.status_code,
          timed_out: mapper.timed_out,
        }
        tar.add_file("#{i}.json", 0644) { |io| io.write status.to_json }
      end
    end
    tar_buffer.rewind
    tar_buffer
  end
  private :mapper_tar_context
end
