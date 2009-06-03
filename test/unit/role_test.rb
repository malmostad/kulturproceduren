require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  test "find by symbol" do
    assert_equal roles(:apa).id, Role.find_by_symbol(:apa).id
  end

  test "find by symbol case insensitive" do
    assert_equal roles(:apa).id, Role.find_by_symbol(:APA).id
  end

  test "symbol name" do
    r = Role.find roles(:apa).id
    assert_equal :apa, r.symbol_name
  end

  test "is?" do
    r = Role.find roles(:apa).id
    assert r.is?(:apa)
    assert r.is?(:APA)
    assert !r.is?(:bepa)
  end
end
