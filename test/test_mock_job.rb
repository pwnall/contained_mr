require 'helper'
require_relative 'concerns/job_state_cases.rb'

class TestMockJob < MiniTest::Test
  def setup
    ContainedMr.stubs(:template_class).returns ContainedMr::Mock::Template
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = ContainedMr::Mock::Job.new @template, 'testjob',
        JSON.load(File.read('testdata/job.hello'))
  end

  def test_mocking_setup
    assert_instance_of ContainedMr::Mock::Template, @template
    assert_instance_of ContainedMr::Mock::Job, @job
  end

  def test_constructor_readers
    assert_equal @template, @job.template
    assert_equal 'contained_mrtests', @job.name_prefix
    assert_equal 'testjob', @job.id
    assert_equal 3, @job.item_count

    assert_equal 2.5, @job._json_options['mapper']['wait_time']
    assert_equal nil, @job._mapper_input
  end

  def test_build_mapper_image
    input = File.read('testdata/input.hello')

    assert_equal nil, @job.mapper_image_id
    assert_equal 'mock-job-mapper-image-id', @job.build_mapper_image(input)
    assert_equal 'mock-job-mapper-image-id', @job.mapper_image_id

    assert_equal input, @job._mapper_input
  end

  def test_run_mapper
    @job.build_mapper_image File.read('testdata/input.hello')

    mock_runner = @job._mock_mapper_runner 2
    assert_equal nil, @job.mapper_runner(2)
    assert_equal mock_runner, @job.run_mapper(2)
    assert_equal mock_runner, @job.mapper_runner(2)

    assert_equal 2.5, mock_runner._time_limit
  end

  def test_mock_mapper_runner
    assert_raises ArgumentError do
      @job._mock_mapper_runner 4
    end
    mock_runners = (1..3).map { |i| @job._mock_mapper_runner i }
    assert_operator mock_runners[0], :!=, mock_runners[1]
    assert_operator mock_runners[0], :!=, mock_runners[2]
    assert_operator mock_runners[1], :!=, mock_runners[2]

    @job.build_mapper_image File.read('testdata/input.hello')

    assert_equal mock_runners[0], @job.run_mapper(1)
    assert_equal mock_runners[1], @job.run_mapper(2)
    assert_equal mock_runners[2], @job.run_mapper(3)
  end

  def test_build_reducer_image
    @job.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| @job.run_mapper i }

    assert_equal nil, @job.reducer_image_id
    assert_equal 'mock-job-reducer-image-id', @job.build_reducer_image
    assert_equal 'mock-job-reducer-image-id', @job.reducer_image_id
  end

  def test_run_reducer
    @job.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| @job.run_mapper i }
    @job.build_reducer_image

    mock_runner = @job._mock_reducer_runner
    assert_equal nil, @job.reducer_runner
    assert_equal mock_runner, @job.run_reducer
    assert_equal mock_runner, @job.reducer_runner

    assert_equal 2, mock_runner._time_limit
  end

  def test_destroy
    assert_equal false, @job.destroyed?
    assert_equal @job, @job.destroy!
    assert_equal true, @job.destroyed?
  end

  include JobStateCases
end
