require 'helper'

class TestMockTemplate < MiniTest::Test
  def setup
    ContainedMr.stubs(:template_class).returns ContainedMr::Mock::Template
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
  end

  def test_mocking_setup
    assert_instance_of ContainedMr::Mock::Template, @template
  end

  def test_constructor_readers
    assert_equal 'contained_mrtests', @template.name_prefix
    assert_equal 'hello', @template.id
  end

  def test_image_id
    assert_equal 'mock-template-image-id', @template.image_id
  end

  def test_definition
    assert_equal 3, @template.item_count
    assert_equal '/usr/mrd/map-output',
        @template._definition['mapper']['output']
  end

  def test_zip_contents
    assert_equal "Hello world!\n", @template._zip_contents['data/hello.txt']
    assert_equal :directory, @template._zip_contents['data/']
  end

  def test_destroy
    assert_equal false, @template.destroyed?
    @template.destroy!
    assert_equal true, @template.destroyed?
  end
end
