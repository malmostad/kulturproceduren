require 'test_helper'

class GroupTest < ActiveSupport::TestCase

  test "number of children by age span" do
    g = Group.find groups(:foo_bepa_klass_xa).id

    num = g.age_groups.num_children_by_age_span(10, 11)
    assert_equal age_groups(:fb_xa1).quantity + age_groups(:fb_xa2).quantity, num
    num = g.age_groups.num_children_by_age_span(10, 10)
    assert_equal age_groups(:fb_xa1).quantity, num
    num = g.age_groups.num_children_by_age_span(8, 9)
    assert_equal 0, num
  end

  test "total children" do
    g = Group.find groups(:foo_bepa_klass_xa).id
    assert_equal age_groups(:fb_xa1).quantity + age_groups(:fb_xa2).quantity + age_groups(:fb_xa3).quantity, g.total_children
  end
end
