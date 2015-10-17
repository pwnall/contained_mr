# @see {ContainedMr::Runner}
class ContainedMr::Mock::Runner
  # @return {Hash<String, Object>} the options passed to the constructor
  attr_reader :_container_options
  # @return {Hash<String, Object>} the time limit passed to the constructor
  attr_reader :_time_limit
  # @return {Hash<String, Object>} the output path passed to the constructor
  attr_reader :_output_path

  # @return {Boolean} true if {#perform} was called
  def performed?
    @performed
  end

  # @return {Boolean} true if {#destroy!} was called
  def destroyed?
    @destroyed
  end

  include ContainedMr::RunnerLogic

  # @see {ContainedMr::Runner#initialize}
  def initialize(container_options, time_limit, output_path)
    @_container_options = container_options
    @_time_limit = time_limit
    @_output_path = output_path

    @container_id = nil
    @started_at = @ended_at = nil
    @status_code = nil
    @timed_out = nil
    @stdout = @stderr = nil
    @output = nil

    @performed = false
    @destroyed = false
  end

  # @see {ContainedMr::Runner#perform}
  def perform
    @performed = true
    self
  end

  # @see {ContainedMr::Runner#destroy!}
  def destroy!
    @destroyed = true
    self
  end

  # Sets the container execution data returned by the mock.
  #
  # @param {Hash<Symbol, Object>} attributes values describing the result of
  #   running the job
  # @return {ContainedMr::Runner} self
  def _mock_set(attributes)
    @started_at = attributes[:started_at]
    @ended_at = attributes[:ended_at]
    @status_code = attributes[:status_code]
    @timed_out = attributes[:timed_out]
    @stdout = attributes[:stdout]
    @stderr = attributes[:stderr]
    @output = attributes[:output]
    self
  end

  # Convenience method for looking up an ulimit in the container options.
  #
  # @param {String} name the ulimit's name, such as 'cpu' or 'rss'
  # @return {Number} the ulimit's hard and soft value, or nil if the ulimit was
  #   not found
  # @raise {RuntimeError} if the ulimit's hard and soft values don't match
  def _ulimit(name)
    return nil unless ulimits = @_container_options['Ulimits']

    ulimits.each do |ulimit|
      if ulimit['Name'] == name
        if ulimit['Hard'] != ulimit['Soft']
          raise RuntimeError, "Hard/soft ulimit mismatch for #{name}"
        end
        return ulimit['Hard']
      end
    end
    nil
  end

  # Convenience method for looking up the RAM limit in the container options.
  #
  # @return {Number} the container's RAM limit, in megabytes
  def _ram_limit
    return nil unless host_config = @_container_options['HostConfig']
    return nil unless memory = host_config['Memory']
    memory / (1024 * 1024).to_f
  end

  # Convenience method for looking up the swap limit in the container options.
  #
  # @return {Number} the container's swap limit, in megabytes
  def _swap_limit
    return nil unless host_config = @_container_options['HostConfig']
    return nil unless memory = host_config['Memory']
    return nil unless memory_swap = host_config['MemorySwap']

    (memory_swap - memory) / (1024 * 1024).to_f
  end

  # Convenience method for looking up CPU allocation in the container options.
  #
  # @return {Number} the number of CPU cores allocated to the container; this
  #   can be a fraction
  def _vcpus
    return nil unless host_config = @_container_options['HostConfig']
    return nil unless period = host_config['CpuPeriod']
    return nil unless quota = host_config['CpuQuota']

    quota / period.to_f
  end

  # Convenience method for looking up the log size limit in container options.
  #
  # @return {Number} the container's log limit, in megabytes
  def _logs
    return nil unless host_config = @_container_options['HostConfig']
    return nil unless log_config = host_config['LogConfig']
    return nil unless config = log_config['Config']
    return nil unless max_size = config['max-size']

    max_size.to_i / (1024 * 1024).to_f
  end
end
