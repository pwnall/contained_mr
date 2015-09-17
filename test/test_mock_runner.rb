require 'helper'

class TestMockRunner < MiniTest::Test
  def setup
    @container_options =  {
      'name' => 'contained_mrtests_mapper.testjob.2',
      'Image' => 'mapperimageid',
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
    @runner = ContainedMr::Mock::Runner.new @container_options, 2.5,
                                            '/usr/mrd/map-output'
  end

  def test_constructor_readers
    assert_equal @container_options, @runner._container_options
    assert_equal 2.5, @runner._time_limit
    assert_equal '/usr/mrd/map-output', @runner._output_path
  end

  def test_perform
    assert_equal false, @runner.performed?
    assert_equal @runner, @runner.perform
    assert_equal true, @runner.performed?
  end

  def test_destroy
    assert_equal false, @runner.destroyed?
    assert_equal @runner, @runner.destroy!
    assert_equal true, @runner.destroyed?
  end

  def test_json_file
    @runner._mock_set status_code: 1, timed_out: true

    golden_json = { ran_for: nil, exit_code: 1, timed_out: true }
    assert_equal golden_json, @runner.json_file
  end

  def test_mock_set
    assert_equal nil, @runner.started_at
    assert_equal nil, @runner.ended_at
    assert_equal nil, @runner.status_code
    assert_equal nil, @runner.timed_out
    assert_equal nil, @runner.stdout
    assert_equal nil, @runner.stderr
    assert_equal nil, @runner.output

    t0 = Time.now
    t1 = t0 + 42
    @runner._mock_set started_at: t0, ended_at: t1, status_code: 1,
        timed_out: false, stdout: 'Hello world!',
        stderr: 'Nothing to see here', output: 'Ohai'

    assert_equal t0, @runner.started_at
    assert_equal t1, @runner.ended_at
    assert_equal 1, @runner.status_code
    assert_equal false, @runner.timed_out
    assert_equal 'Hello world!', @runner.stdout
    assert_equal 'Nothing to see here', @runner.stderr
    assert_equal 'Ohai', @runner.output
  end

  def test_ulimit
    assert_equal 3, @runner._ulimit('cpu')
    assert_equal 1000000, @runner._ulimit('rss')
    assert_equal nil, @runner._ulimit('nothing')
  end

  def test_ulimit_with_mismatched_values
    @container_options['Ulimits'][0]['Hard'] = 1
    runner = ContainedMr::Mock::Runner.new @container_options, 2.5,
                                           '/usr/mrd/map-output'
    assert_equal 1000000, runner._ulimit('rss')

    begin
      runner._ulimit('cpu')
      flunk 'No exception thrown'
    rescue RuntimeError => e
      assert_instance_of RuntimeError, e
      assert_equal 'Hard/soft ulimit mismatch for cpu', e.message
    end
  end

  def test_ulimit_with_missing_ulimits_array
    @container_options.delete 'Ulimits'
    runner = ContainedMr::Mock::Runner.new @container_options, 2.5,
                                           '/usr/mrd/map-output'
    assert_equal nil, runner._ulimit('cpu')
    assert_equal nil, runner._ulimit('rss')
  end
end
