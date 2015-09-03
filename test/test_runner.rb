require 'helper'

class TestRunner < MiniTest::Test
  def setup
    @template = ContainedMr::Template.new 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = ContainedMr::Job.new @template, 'testjob',
                                JSON.load(File.read('testdata/job.hello'))
    @job.build_mapper_image File.read('testdata/input.hello')
  end

  def teardown
    @job.destroy!
    @template.destroy!
  end

  def test_perform_happy_path
    runner = ContainedMr::Runner.new @job.mapper_container_options(2), 2.5,
                                     @template.mapper_output_path
    runner.perform

    assert_equal nil, runner.container_id, 'container still running'
    assert_operator runner.ended_at - runner.started_at, :<, 1, 'running time'
    assert_equal 0, runner.status_code, 'status code'
    assert_equal false, runner.timed_out, 'timed out'
    assert_equal "2 3\n", runner.stderr, 'Stderr: $ITEM + $ITEMS'
    assert_equal "2\nmapper input file\nHello world!\n", runner.stdout,
                 'Stdout: $ITEM + mapper input file + data file'
    assert_equal "2\n", runner.output, 'Output: ITEM env variable'
  end

  def test_perform_exit_code
    runner = ContainedMr::Runner.new @job.mapper_container_options(3), 2.5,
                                     @template.mapper_output_path
    runner.perform

    assert_equal nil, runner.container_id, 'container still running'
    assert_operator runner.ended_at - runner.started_at, :<, 1, 'running time'
    assert_equal 42, runner.status_code, 'status code'
    assert_equal false, runner.timed_out, 'timed out'
  end

  def test_perform_timeout
    runner = ContainedMr::Runner.new @job.mapper_container_options(1), 2.5,
                                     @template.mapper_output_path
    runner.perform

    assert_equal nil, runner.container_id, 'container still running'
    assert_equal false, runner.status_code, 'status code'
    assert_equal true, runner.timed_out, 'timed out'
    assert_operator runner.ended_at - runner.started_at, :>, 2.2,
                    'running time'
    assert_operator runner.ended_at - runner.started_at, :<, 2.8,
                    'running time'
  end
end
