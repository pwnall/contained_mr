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
end
