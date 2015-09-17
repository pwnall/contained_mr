require 'helper'

class TestCleaner < MiniTest::Test
  def setup
    @template = ContainedMr::Template.new 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = @template.new_job 'testjob',
        JSON.load(File.read('testdata/job.hello'))
    @job.build_mapper_image File.read('testdata/input.hello')

    @cleaner = ContainedMr::Cleaner.new 'contained_mrtests'
  end

  def test_destroy_all
    @cleaner.destroy_all!
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @job.mapper_image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @template.image_tag
    end
  end

  def test_destroy_all_with_duplicates
    template2 = ContainedMr::Template.new 'contained_mrtests', 'hello2',
        StringIO.new(File.binread('testdata/hello.zip'))
    job2 = template2.new_job 'testjob2',
        JSON.load(File.read('testdata/job.hello'))
    job2.build_mapper_image File.read('testdata/input.hello')
    @cleaner.destroy_all!
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get job2.mapper_image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get template2.image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @job.mapper_image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @template.image_tag
    end
  end
end
