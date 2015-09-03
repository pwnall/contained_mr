require 'helper'

class TestTemplate < MiniTest::Test
  def setup
    @template = ContainedMr::Template.new 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
  end

  def teardown
    @template.destroy!
  end

  def test_image_id_matches_created_image
    image = Docker::Image.get @template.image_tag
    assert image, 'Docker::Image'
    assert_operator image.id, :start_with?, @template.image_id
  end

  def test_image_tag
    assert_equal 'contained_mrtests/base.hello', @template.image_tag
  end

  def test_dockerfiles
    golden = File.read 'testdata/Dockerfile.hello.mapper'
    golden.sub! 'contained_mrtests/base.hello', @template.image_id
    assert_equal golden, @template.mapper_dockerfile, 'mapper Dockerfile'

    golden = File.read 'testdata/Dockerfile.hello.reducer'
    golden.sub! 'contained_mrtests/base.hello', @template.image_id
    assert_equal golden, @template.reducer_dockerfile, 'reducer Dockerfile'
  end

  def test_paths
    assert_equal '/usr/mrd/map-output', @template.mapper_output_path
    assert_equal '/usr/mrd/reduce-output', @template.reducer_output_path
  end

  def test_envs
    assert_equal 3, @template.item_count
    assert_equal ['ITEM=2', 'ITEMS=3'], @template.mapper_env(2)
    assert_equal ['ITEMS=3'], @template.reducer_env
  end

  def test_destroy
    @template.destroy!
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @template.image_tag
    end
  end
end
