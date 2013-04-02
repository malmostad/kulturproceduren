require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  test "validations" do
    category = build(:category, :name => "")
    assert !category.valid?
    assert_not_nil category.errors.on(:name)
  end
end
