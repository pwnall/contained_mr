require 'helper'

class TestJobLogic < MiniTest::Test
  def setup
    ContainedMr.stubs(:template_class).returns ContainedMr::Mock::Template
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = @template.new_job 'testjob',
        JSON.load(File.read('testdata/job.hello'))
  end

  def test_mapper_image_tag
    assert_equal 'contained_mrtests/mapper.testjob', @job.mapper_image_tag
  end

  def test_reducer_image_tag
    assert_equal 'contained_mrtests/reducer.testjob', @job.reducer_image_tag
  end

  def test_mapper_container_options
    assert_equal @template, @job.template
    assert_equal 'contained_mrtests', @job.name_prefix
    assert_equal 'testjob', @job.id
    assert_equal 3, @job.item_count

    @job.build_mapper_image File.read('testdata/input.hello')

    golden = {
      'name' => 'contained_mrtests_mapper.testjob.2',
      'Image' => 'contained_mrtests/mapper.testjob',
      'Hostname' => '2.mapper',
      'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => 'contained_mrtests' },
      'Env' => [ 'ITEM=2', 'ITEMS=3',
                 'affinity:image==contained_mrtests/mapper.testjob' ],
      'Ulimits' => [
        { 'Name' => 'cpu', 'Hard' => 3, 'Soft' => 3 },
      ],
      'NetworkDisabled' => true, 'ExposedPorts' => {},
      'HostConfig' => {
        'Memory' => 256.5 * 1024 * 1024,
        'MemorySwap' => (256.5 + 64) * 1024 * 1024,
        'CpuShares' => 1500000,
        'CpuPeriod' => 1000000,
      },
    }
    assert_equal golden, @job.mapper_container_options(2)
  end

  def test_reducer_container_options
    golden = {
      'name' => 'contained_mrtests_reducer.testjob',
      'Image' => 'contained_mrtests/reducer.testjob',
      'Hostname' => 'reducer',
      'Domainname' => '',
      'Labels' => { 'contained_mr.ctl' => 'contained_mrtests' },
      'Env' => [ 'ITEMS=3',
                 'affinity:image==contained_mrtests/reducer.testjob' ],
      'Ulimits' => [
        { 'Name' => 'cpu', 'Hard' => 2, 'Soft' => 2 },
      ],
      'NetworkDisabled' => true, 'ExposedPorts' => {},
      'HostConfig' => {
        'Memory' => 768.5 * 1024 * 1024,
        'MemorySwap' => -1,
        'CpuShares' => 500000,
        'CpuPeriod' => 1000000,
      },
    }
    assert_equal golden, @job.reducer_container_options
  end
end
