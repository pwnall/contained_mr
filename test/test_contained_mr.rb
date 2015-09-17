require 'helper'

class TestContainedMr < MiniTest::Test
  def test_template_class
    assert_equal ContainedMr::Template, ContainedMr.template_class
  end

  def test_new_template
    ContainedMr.stubs(:template_class).returns ContainedMr::Mock::Template

    template = ContainedMr.new_template 'contained_mrtests', 'hello',
        StringIO.new(File.binread('testdata/hello.zip'))
    assert_instance_of ContainedMr::Mock::Template, template
  end
end
