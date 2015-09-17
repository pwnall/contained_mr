require 'helper'

class TestJobLogic < MiniTest::Test
  def setup
    ContainedMr.stubs(:template_class).returns ContainedMr::Mock::Template
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = @template.new_job 'testjob',
        JSON.load(File.read('testdata/job.hello'))
  end

  def test_mapper_container_options
    assert_equal @template, @job.template
    assert_equal 'contained_mrtests', @job.name_prefix
    assert_equal 'testjob', @job.id
    assert_equal 3, @job.item_count

    @job.build_mapper_image File.read('testdata/input.hello')

    golden = {
      'name' => 'contained_mrtests_mapper.testjob.2',
      'Image' => @job.mapper_image_id,
      'Hostname' => '2.mapper',
      'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => 'contained_mrtests' },
      'Env' => [ 'ITEM=2', 'ITEMS=3' ],
      'Ulimits' => [
        { 'Name' => 'cpu', 'Hard' => 3, 'Soft' => 3 },
        { 'Name' => 'rss', 'Hard' => 1000000, 'Soft' => 1000000 },
      ],
      'NetworkDisabled' => true, 'ExposedPorts' => {},
    }
    assert_equal golden, @job.mapper_container_options(2)
  end

  def test_reducer_container_options
    golden = {
      'name' => 'contained_mrtests_reducer.testjob',
      'Image' => @job.mapper_image_id,
      'Hostname' => 'reducer',
      'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => 'contained_mrtests' },
      'Env' => [ 'ITEMS=3' ],
      'Ulimits' => [
        { 'Name' => 'cpu', 'Hard' => 2, 'Soft' => 2 },
        { 'Name' => 'rss', 'Hard' => 100000, 'Soft' => 100000 },
      ],
      'NetworkDisabled' => true, 'ExposedPorts' => {},
    }
    assert_equal golden, @job.reducer_container_options
  end
end
