# Logic shared by {ContainedMr::Job} and {ContainedMr::Mock::Job}.
module ContainedMr::JobLogic
  # @return {ContainedMr::Template} the template this job is derived from
  attr_reader :template

  # @return {String} prepended to Docker objects, for identification purposes
  attr_reader :name_prefix

  # @return {String} the job's unique identifier
  attr_reader :id

  # @return {Number} the number of mapper jobs that will be run
  attr_reader :item_count

  # @return {String} the unique ID of the Docker image used to run the mappers
  attr_reader :mapper_image_id

  # @return {String} the unique ID of the Docker image used to run the reducer
  attr_reader :reducer_image_id

  # Returns the runner used for a mapper.
  #
  # @param {Number} i the mapper number
  # @return {ContainedMr::Runner} the runner used for the given mapper; nil if
  #   the given mapper was not started
  def mapper_runner(i)
    if i < 1 || i > @item_count
      raise ArgumentError, "Invalid mapper number #{i}"
    end
    @mappers[i - 1]
  end

  # Returns the runner used for the reducer.
  #
  # @return {ContainedMr::Runner} the runner used for reducer; nil if the
  #   reducer was not started
  def reducer_runner
    @reducer
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

    env = @template.mapper_env i
    env.push "affinity:image==#{mapper_image_tag}"

    {
      'name' => "#{@name_prefix}_mapper.#{@id}.#{i}",
      'Image' => mapper_image_tag,
      'Hostname' => "#{i}.mapper", 'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => @name_prefix },
      'Env' => env, 'Ulimits' => ulimits,
      'NetworkDisabled' => true, 'ExposedPorts' => {},
      'HostConfig' => container_host_config(@mapper_options),
    }
  end

  # @return {Hash<String, Object>} params used to create a reducer container
  def reducer_container_options
    ulimits = @reducer_options[:ulimits].map do |k, v|
      { "Name" => k.to_s, "Soft" => v, "Hard" => v }
    end

    env = @template.reducer_env
    env.push "affinity:image==#{reducer_image_tag}"

    {
      'name' => "#{@name_prefix}_reducer.#{@id}",
      'Image' => reducer_image_tag,
      'Hostname' => 'reducer', 'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => @name_prefix },
      'Env' => env, 'Ulimits' => ulimits,
      'NetworkDisabled' => true, 'ExposedPorts' => {},
      'HostConfig' => container_host_config(@reducer_options),
    }
  end

  # Computes the value of the HostConfig key in container creation params.
  #
  # @param {Hash<Symbol, Object>} job_section the "mapper" or "reducer" section
  #   in the options
  # @return {Hash<String, Object>} a container's HostConfig params
  def container_host_config(job_section)
    ram_bytes = (job_section[:ram] * 1048576).to_i
    swap_bytes = (job_section[:swap] * 1048576).to_i + ram_bytes

    # NOTE: The value below is 1 second, in microsecodns. This is the maximum
    #       value, and it minimizes scheduling overheads, at the expense of
    #       precision.
    cpu_period = 1_000_000

    {
      'Memory' => ram_bytes, 'MemorySwap' => swap_bytes,
      'MemorySwappiness' => 0,
      'CpuPeriod' => cpu_period,
      'CpuQuota' => (job_section[:vcpus] * cpu_period).to_i,
      'LogConfig' => {
        'Type' => 'json-file',
        'Config' => {
          'max-size' => (job_section[:logs] * 1048576).to_i.to_s,
          'max-file' => '1',
        },
      },
    }
  end
  private :container_host_config

  # Reads in JSON options and sets defaults.
  def parse_options(json_options)
    mapper = json_options['mapper'] || {}
    mapper_ulimits = mapper['ulimits'] || {}
    @mapper_options = {
      wait_time: mapper['wait_time'] || 60,
      vcpus: mapper['vcpus'] || 1,  # logical processors
      ram: mapper['ram'] || 512,    # megabytes
      swap: mapper['swap'] || 0,    # megabytes
      logs: mapper['logs'] || 64,   # megabytes
      ulimits: {
        cpu: mapper_ulimits['cpu'] || 60,  # seconds
      }
    }

    reducer = json_options['reducer'] || {}
    reducer_ulimits = reducer['ulimits'] || {}
    @reducer_options = {
      wait_time: reducer['wait_time'] || 60,
      vcpus: reducer['vcpus'] || 1,  # logical processors
      ram: reducer['ram'] || 512,    # megabytes
      swap: reducer['swap'] || 0,    # megabytes
      logs: reducer['logs'] || 64,   # megabytes
      ulimits: {
        cpu: reducer_ulimits['cpu'] || 60,
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
end
