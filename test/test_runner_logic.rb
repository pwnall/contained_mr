require 'helper'

class TestRunnerLogic < MiniTest::Test
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
      ],
      'NetworkDisabled' => true, 'ExposedPorts' => {},
      'HostConfig' => {
        'Memory' => 256.5 * 1024 * 1024,
        'MemorySwap' => (256.5 + 64) * 1024 * 1024,
        'MemorySwappiness' => 0,
        'CpuQuota' => 1000000,
        'CpuPeriod' => 1000000,
        'CpuShares' => 1,
        'LogConfig' => {
          'Type' => 'json-file',
          'Config' => {
            'max-size' => '4718592',
            'max-file' => '1',
          },
        },
      },
    }
    @runner = ContainedMr::Mock::Runner.new @container_options, 2.5,
                                            '/usr/mrd/map-output'
  end

  def test_ran_for_with_nil_start_end
    assert_equal nil, @runner.ran_for
  end

  def test_ran_for_with_nil_end
    @runner._mock_set started_at: Time.now
    assert_equal nil, @runner.ran_for
  end

  def test_ran_for_with_nil_start
    @runner._mock_set ended_at: Time.now
    assert_equal nil, @runner.ran_for
  end

  def test_ran_for_with_start_and_end
    t0 = Time.now
    @runner._mock_set started_at: t0, ended_at: t0 + 42
    assert_equal 42, @runner.ran_for
  end

  def test_json_file
    t0 = Time.now
    t1 = t0 + 42
    @runner._mock_set started_at: t0, ended_at: t1, status_code: 1,
                      timed_out: false

    golden_json = { ran_for: 42, exit_code: 1, timed_out: false }
    assert_equal golden_json, @runner.json_file
  end
end
