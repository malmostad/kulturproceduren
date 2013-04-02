require 'test_helper'

class CategoryGroupTest < ActiveSupport::TestCase
  test "validations" do
    category_group = build(:category_group, :name => "")
    assert !category_group.valid?
    assert_not_nil category_group.errors.on(:name)
  end
end
