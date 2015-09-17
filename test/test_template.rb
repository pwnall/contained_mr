require 'helper'

class TestTemplate < MiniTest::Test
  def setup
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
  end

  def teardown
    @template.destroy!
  end

  def test_image_id_matches_created_image
    assert_equal 'contained_mrtests', @template.name_prefix
    assert_equal 'hello', @template.id

    image = Docker::Image.get @template.image_tag
    assert image, 'Docker::Image'
    assert_operator image.id, :start_with?, @template.image_id
  end

  def test_created_image_tags
    images = Docker::Image.all
    image = images.find { |i| i.id.start_with? @template.image_id }
    assert image, 'Docker::Image in collection returned by Docker::Image.all'
    assert image.info['RepoTags'], "Image missing RepoTags: #{image.inspect}"
    assert_includes image.info['RepoTags'],
        'contained_mrtests/base.hello:latest'
  end

  def test_destroy
    assert_equal @template, @template.destroy!
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @template.image_tag
    end
  end

  def test_destory_with_two_templates
    template2 = ContainedMr.new_template 'contained_mrtests', 'hello2',
        StringIO.new(File.binread('testdata/hello.zip'))

    assert_equal template2, template2.destroy!
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get template2.image_tag
    end

    image = Docker::Image.get @template.image_tag
    assert image, "destroy! wiped the other template's image"

    assert_equal @template, @template.destroy!
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @template.image_tag
    end
  end
end
