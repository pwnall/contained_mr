require 'helper'

class TestTemplateLogic < MiniTest::Test
  def setup
    ContainedMr.stubs(:template_class).returns ContainedMr::Mock::Template
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
  end

  def test_mapper_dockerfile
    golden = File.read 'testdata/Dockerfile.hello.mapper'
    assert_equal golden, @template.mapper_dockerfile, 'mapper Dockerfile'
  end

  def test_reducer_dockerfile
    golden = File.read 'testdata/Dockerfile.hello.reducer'
    assert_equal golden, @template.reducer_dockerfile, 'reducer Dockerfile'
  end

  def test_mapper_output_path
    assert_equal '/usr/mrd/map-output', @template.mapper_output_path
  end

  def test_reducer_output_path
    assert_equal '/usr/mrd/reduce-output', @template.reducer_output_path
  end

  def test_image_tag
    assert_equal 'contained_mrtests/base.hello', @template.image_tag
  end

  def test_mapper_env
    assert_equal ['ITEM=1', 'ITEMS=3'], @template.mapper_env(1)
    assert_equal ['ITEM=2', 'ITEMS=3'], @template.mapper_env(2)
    assert_equal ['ITEM=3', 'ITEMS=3'], @template.mapper_env(3)
  end

  def test_reducer_env
    assert_equal ['ITEMS=3'], @template.reducer_env
  end

  def test_read_definition
    assert_equal 3, @template.item_count
  end
end
