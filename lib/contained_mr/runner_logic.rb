# Logic shared by {ContainedMr::Runner} and {ContainedMr::Mock::Runner}.
module ContainedMr::RunnerLogic
  # @return {Time} the time when the mapper or reducer starts running
  attr_reader :started_at
  # @return {Time} the time when the mapper or reducer stops running or is killed
  attr_reader :ended_at
  # @return {Number} the time
  attr_reader :status_code
  # @return {Boolean} true if the mapper or reducer was terminated due to
  #   running for too long
  attr_reader :timed_out

  # @return {String} the data written by the mapper or reducer to stdout
  attr_reader :stdout
  # @return {String} the data written by the mapper or reducer to stderr
  attr_reader :stderr
  # @return {String} the contents of the file
  attr_reader :output

  # @return {String} the unique ID of the Docker container used to run the
  #   mapper / reducer; this is nil
  attr_reader :container_id

  # @return {Number} the container's running time, in seconds
  def ran_for
    started_at && ended_at && (ended_at - started_at)
  end

  # The information written to the mapper status files given to the reducer.
  #
  # This is saved in files named 1.json, 2.json, ... provided to the reducer.
  #
  # @return {Hash<Symbol, Object>} JSON-compatible representation of the
  #   runner's information
  def json_file
    { ran_for: ran_for, exit_code: status_code, timed_out: timed_out }
  end
end
