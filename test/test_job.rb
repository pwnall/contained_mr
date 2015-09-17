require 'helper'
require_relative 'concerns/job_state_cases.rb'

class TestJob < MiniTest::Test
  def setup
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = @template.new_job 'testjob',
        JSON.load(File.read('testdata/job.hello'))
  end

  def teardown
    @job.destroy!
    @template.destroy!
  end

  def test_build_mapper_image
    assert_equal 'contained_mrtests/mapper.testjob', @job.mapper_image_tag

    assert_equal nil, @job.mapper_image_id
    mapper_return = @job.build_mapper_image File.read('testdata/input.hello')
    assert_equal mapper_return, @job.mapper_image_id

    image = Docker::Image.get @job.mapper_image_tag
    assert image, 'Docker::Image'
    assert_operator image.id, :start_with?, @job.mapper_image_id

    1.upto 3 do |i|
      assert_nil @job.mapper_runner(i), "Mapper #{i} started prematurely"
    end
    assert_nil @job.reducer_runner, "Reducer started prematurely"
  end

  def test_created_mapper_image_tags
    @job.build_mapper_image File.read('testdata/input.hello')

    images = Docker::Image.all
    image = images.find { |i| i.id.start_with? @job.mapper_image_id }
    assert image, 'Docker::Image in collection returned by Docker::Image.all'
    assert image.info['RepoTags'], "Image missing RepoTags: #{image.inspect}"
    assert_includes image.info['RepoTags'],
        'contained_mrtests/mapper.testjob:latest'
  end

  def test_run_mapper_stderr
    @job.build_mapper_image File.read('testdata/input.hello')
    runner = @job.run_mapper 2

    assert_equal runner, @job.mapper_runner(2), 'mapper_runner return'
    assert_nil @job.mapper_runner(1), 'Mapper 1 started prematurely'
    assert_nil @job.mapper_runner(3), 'Mapper 3 started prematurely'
    assert_nil @job.reducer_runner, 'Reducer started prematurely'

    mapper = @job.mapper_runner 2
    assert mapper, 'Mapper 2 not started'
    assert_equal nil, mapper.container_id, 'Mapper container still running'
    assert_equal "2 3\n", mapper.stderr, 'Stderr: $ITEM + $ITEMS'
  end

  def test_run_mapper_stdout
    @job.build_mapper_image File.read('testdata/input.hello')
    mapper = @job.run_mapper 2

    assert_equal nil, mapper.container_id, 'Mapper container still running'
    assert_equal "2\nmapper input file\nHello world!\n", mapper.stdout,
                 'Stdout: $ITEM + mapper input file + data file'
  end

  def test_run_mapper_output
    @job.build_mapper_image File.read('testdata/input.hello')
    mapper = @job.run_mapper 2

    assert_equal nil, mapper.container_id, 'Mapper container still running'
    assert_equal "2\n", mapper.output, 'Output: ITEM env variable'
  end

  def test_build_reducer_image
    assert_equal 'contained_mrtests/reducer.testjob', @job.reducer_image_tag

    @job.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| @job.run_mapper i }

    @job.build_reducer_image
    image = Docker::Image.get @job.reducer_image_tag
    assert image, 'Docker::Image'
    assert_operator image.id, :start_with?, @job.reducer_image_id

    assert_nil @job.reducer_runner, "Reducer started prematurely"

    images = Docker::Image.all
    image = images.find { |i| i.id.start_with? @job.reducer_image_id }
    assert image, 'Docker::Image in collection returned by Docker::Image.all'
    assert image.info['RepoTags'], "Image missing RepoTags: #{image.inspect}"
    assert_includes image.info['RepoTags'],
        'contained_mrtests/reducer.testjob:latest'
  end

  def test_run_reducer
    @job.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| @job.run_mapper i }
    @job.build_reducer_image
    reducer = @job.run_reducer

    assert_equal reducer, @job.reducer_runner, 'reducer_runner return'
    assert_equal "3 /\n", reducer.stderr, 'Stderr: $ITEMS + $PWD'

    output_gold = "1\n2\n3\n" +
        "1\nmapper input file\nHello world!\n" +
        "2\nmapper input file\nHello world!\n" +
        "3\nmapper input file\nHello world!\n" +
        "1 3\n2 3\n3 3\n"
    assert_equal output_gold, reducer.output, 'Stderr: mappers out/stdout/err'

    json_texts = reducer.stdout.split("\n")
    assert_equal 3, json_texts.length

    jsons = json_texts.map { |t| JSON.load t }
    assert_equal [false, 0, 42], jsons.map { |j| j['exit_code'] }
    assert_equal [true, false, false], jsons.map { |j| j['timed_out'] }
    assert_operator jsons[0]['ran_for'], :>, 2, 'ran_for in mapper 0'
    assert_operator jsons[1]['ran_for'], :<, 2, 'ran_for in mapper 1'
    assert_operator jsons[2]['ran_for'], :<, 2, 'ran_for in mapper 2'
  end

  def test_destroy
    @job.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| @job.run_mapper i }
    @job.build_reducer_image

    assert_equal @job, @job.destroy!

    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @job.mapper_image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @job.reducer_image_tag
    end
  end

  def test_destroy_with_two_jobs
    @job.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| @job.run_mapper i }
    @job.build_reducer_image

    job2 = @template.new_job 'testjob2',
        JSON.load(File.read('testdata/job.hello'))
    job2.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| job2.run_mapper i }
    job2.build_reducer_image

    assert_equal job2, job2.destroy!

    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get job2.mapper_image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get job2.reducer_image_tag
    end

    image = Docker::Image.get @job.mapper_image_tag
    assert image, "destroy! wiped the other job's mapper image"

    image = Docker::Image.get @job.reducer_image_tag
    assert image, "destroy! wiped the other job's reducer image"

    assert_equal @job, @job.destroy!

    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @job.mapper_image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @job.reducer_image_tag
    end
  end

  include JobStateCases
end
