# Logic shared by {ContainedMr::Runner} and {ContainedMr::Mock::Runner}.
module ContainedMr::RunnerLogic
  # @return {Number} the container's running time, in seconds
  def ran_for
    started_at && ended_at && (ended_at - started_at)
  end

  # The information written to the mapper status files given to the reducer.
  #
  # This is saved in files named {1...n}.json provided to the reducer.
  #
  # @return {Hash<Symbol, Object>} JSON-compatible representation of the
  #   runner's information
  def json_file
    { ran_for: ran_for, exit_code: status_code, timed_out: timed_out }
  end
end
