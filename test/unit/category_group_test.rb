require_relative '../test_helper'

class CategoryGroupTest < ActiveSupport::TestCase
  test "validations" do
    category_group = build(:category_group, name: "")
    assert !category_group.valid?
    assert category_group.errors.include?(:name)
  end
end
