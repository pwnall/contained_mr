require 'helper'

class TestCleaner < MiniTest::Test
  def setup
    @template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    @job = @template.new_job 'testjob',
        JSON.load(File.read('testdata/job.hello'))
    @job.build_mapper_image File.read('testdata/input.hello')
    @runner = ContainedMr::Runner.new @job.mapper_container_options(2), 2.5,
                                      @template.mapper_output_path
    class <<@runner
      def destroy!(*args)
        self
      end
    end
    @runner.perform

    @cleaner = ContainedMr::Cleaner.new 'contained_mrtests'
  end

  def teardown
    Docker::Container.any_instance.unstub :delete
    @cleaner.destroy_all!
  end

  def test_destroy_all
    objects = @cleaner.destroy_all!
    assert_equal 3, objects.length
    assert_kind_of Docker::Container, objects[0]
    assert_kind_of Docker::Image, objects[1]
    assert_kind_of Docker::Image, objects[2]

    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @job.mapper_image_tag
    end
    assert_raises Docker::Error::NotFoundError do
      Docker::Image.get @template.image_tag
    end
  end

  def test_destroy_all_with_duplicates
    template2 = ContainedMr.new_template 'contained_mrtests', 'hello2',
        StringIO.new(File.binread('testdata/hello.zip'))
    job2 = template2.new_job 'testjob2',
        JSON.load(File.read('testdata/job.hello'))
    job2.build_mapper_image File.read('testdata/input.hello')
    runner2 = ContainedMr::Runner.new job2.mapper_container_options(2), 2.5,
                                      template2.mapper_output_path
    class <<runner2
      def destroy!(*args)
        self
      end
    end
    runner2.perform

    objects = @cleaner.destroy_all!
    assert_equal 6, objects.length
    assert_kind_of Docker::Container, objects[0]
    assert_kind_of Docker::Container, objects[1]
    assert_kind_of Docker::Image, objects[2]
    assert_kind_of Docker::Image, objects[3]
    assert_kind_of Docker::Image, objects[4]
    assert_kind_of Docker::Image, objects[5]

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

  def test_destroy_all_containers_with_duplicates_and_exceptions
    template2 = ContainedMr.new_template 'contained_mrtests', 'hello2',
        StringIO.new(File.binread('testdata/hello.zip'))
    job2 = template2.new_job 'testjob2',
        JSON.load(File.read('testdata/job.hello'))
    job2.build_mapper_image File.read('testdata/input.hello')
    runner2 = ContainedMr::Runner.new job2.mapper_container_options(2), 2.5,
                                      template2.mapper_output_path
    class <<runner2
      def destroy!(*args)
        self
      end
    end
    runner2.perform

    Docker::Container.any_instance.expects(:delete).twice.
                      raises Docker::Error::NotFoundError
    containers = @cleaner.destroy_all_containers!
    assert_equal 2, containers.length
    containers.each { |c| assert_kind_of Docker::Container, c }
  end
end
