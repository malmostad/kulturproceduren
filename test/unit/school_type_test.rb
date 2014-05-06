# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class SchoolTypeTest < ActiveSupport::TestCase
  test "validations" do
    school_type = build(:school_type, name: "")
    assert !school_type.valid?
    assert school_type.errors.include?(:name)
  end

  test "default scopes" do
    active   = create(:school_type, active: true)
    inactive = create(:school_type, active: false)
    assert_equal [active], SchoolType.all
  end

  test "active scopes" do
    active   = create(:school_type, active: true)
    inactive = create(:school_type, active: false)
    assert_equal [active],   SchoolType.active
    assert_equal [inactive], SchoolType.inactive
  end
end
