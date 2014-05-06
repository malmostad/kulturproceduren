require_relative '../test_helper'

class RoleTest < ActiveSupport::TestCase
  test "validations" do
    role = build(:role, name: "")
    assert !role.valid?
    assert role.errors.include?(:name)
  end
  test "find by symbol" do
    assert_equal roles(:admin).id, Role.find_by_symbol(:admin).id
    assert_equal roles(:admin).id, Role.find_by_symbol(:aDmIn).id
  end

  test "symbol name" do
    role = Role.find roles(:admin).id
    assert_equal :admin, role.symbol_name
  end

  test "is?" do
    role = Role.find roles(:admin).id
    assert role.is?(:admin)
    assert role.is?(:ADMIN)
    assert !role.is?(:booker)
  end
end
