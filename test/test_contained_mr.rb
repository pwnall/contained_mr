require 'helper'

class TestContainedMr < MiniTest::Test
  def test_template_class
    assert_equal ContainedMr::Template, ContainedMr.template_class
  end
end
