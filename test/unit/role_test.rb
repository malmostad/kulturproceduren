require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  test "find by symbol" do
    assert_equal roles(:admin).id, Role.find_by_symbol(:admin).id
  end

  test "find by symbol case insensitive" do
    assert_equal roles(:admin).id, Role.find_by_symbol(:aDmIn).id
  end

  test "symbol name" do
    r = Role.find roles(:admin).id
    assert_equal :admin, r.symbol_name
  end

  test "is?" do
    r = Role.find roles(:admin).id
    assert r.is?(:admin)
    assert r.is?(:ADMIN)
    assert !r.is?(:booker)
  end
end
