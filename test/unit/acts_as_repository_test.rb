require 'test_helper'

class ActsAsRepositoryTest < ActiveSupport::TestCase

  def test_of_the_instance_function_test_with_user
    user = User.new
    assert_equal "test: Hello World", user.test("Hello World")
  end

  def test_of_the_instance_function_test_with_group
    group = Group.new
    assert_equal "test: Hello World", group.test("Hello World")
  end

end