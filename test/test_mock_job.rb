require 'helper'
require_relative 'concerns/job_state_cases.rb'

class TestMockJob < MiniTest::Test
  def setup
    @template = ContainedMr::Mock::Template.new 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = ContainedMr::Mock::Job.new @template, 'testjob',
        JSON.load(File.read('testdata/job.hello'))
  end

  def test_constructor_readers
    assert_equal @template, @job.template
    assert_equal 'contained_mrtests', @job.name_prefix
    assert_equal 'testjob', @job.id
    assert_equal 3, @job.item_count

    assert_equal nil, @job._mapper_input
  end

  def test_build_mapper_image
    input = File.read('testdata/input.hello')
    assert_equal '', @job.build_mapper_image(input)
    assert_equal input, @job._mapper_input
  end

  def test_destroy
    assert_equal false, @job.destroyed?
    assert_equal @job, @job.destroy!
    assert_equal true, @job.destroyed?
  end

  include JobStateCases
end
