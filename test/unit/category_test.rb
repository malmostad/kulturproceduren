require_relative '../test_helper'

class CategoryTest < ActiveSupport::TestCase
  test "validations" do
    category = build(:category, name: "")
    assert !category.valid?
    assert category.errors.include?(:name)
  end
end
