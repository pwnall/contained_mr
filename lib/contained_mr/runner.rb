require 'rubygems'  # For tar operations.
require 'stringio'

require 'docker'

# Handles running a single mapper or reducer.
class ContainedMr::Runner
  attr_reader :container_id
  attr_reader :started_at, :ended_at, :status_code, :timed_out
  attr_reader :stdout, :stderr, :output

  # C
  def initialize(container_options, time_limit, output_path)
    @container_options = container_options
    @time_limit = time_limit
    @output_path = output_path

    @container_id = nil
    @started_at = @ended_at = nil
    @status_code = nil
    @timed_out = nil
    @stdout = @stderr = nil
    @output = nil
  end


  # Performs a full mapper / reducer step.
  def perform
    container = create
    @container_id = container.id

    execute container
    fetch_console_output container
    fetch_file_output container
    destroy container
    self
  end

  # @return {Number} the container's running time, in seconds
  def ran_for
    @started_at && @ended_at && (@ended_at - @started_at)
  end

  # Creates a container for running a mapper or reducer.
  #
  # @return {Docker::Container} newly created container
  def create
    Docker::Container.create @container_options
  end
  private :create

  # Runs the process inside the container, kills it if takes too long.
  #
  # @param {Docker::Container} container the container that holds the process
  def execute(container)
    container.start
    @started_at = Time.now
    begin
      wait_status = container.wait @time_limit
      @status_code = wait_status['StatusCode']
      @timed_out = false
    rescue Docker::Error::TimeoutError
      @status_code = false
      @timed_out = true
      container.kill
    end
    @ended_at = Time.now
  end
  private :execute

  # Extracts console output from a container.
  #
  # @param {Docker::Container} container the mapper / reducer's container
  def fetch_console_output(container)
    messages = container.attach stream: false, logs: true, stdin: nil,
                                stdout: true, stderr: true
    @stdout = messages[0].join ''
    @stderr = messages[1].join ''
  end
  private :fetch_console_output

  # Extracts the mapper / reducer's output file from a container.
  #
  # @param {Docker::Container} container the mapper / reducer's container
  def fetch_file_output(container)
    begin
      tar_buffer = fetch_tar_output container
    rescue Docker::Error::ServerError
      @output = false
      return
    end

    Gem::Package::TarReader.new tar_buffer do |tar|
      tar.each do |entry|
        next unless entry.file?
        @output = entry.read
        return
      end
    end
    @output = false
  end
  private :fetch_file_output

  # Extracts the mapper / reducer's output, as a .tar, from a container.
  #
  # @param {Docker::Container} container the mapper / reducer's container
  # @return {IO} an IO implementation that sources the .tar data
  def fetch_tar_output(container)
    tar_buffer = StringIO.new
    container.copy @output_path do |data|
      tar_buffer << data
    end
    tar_buffer.rewind
    tar_buffer
  end
  private :fetch_tar_output

  # Removes the container used to run a mapper / reducer.
  #
  # @param {Docker::Container} container the mapper / reducer's container
  def destroy(container)
    container.delete
    @container_id = nil
  end
end
