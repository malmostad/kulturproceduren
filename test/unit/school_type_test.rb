# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class SchoolTypeTest < ActiveSupport::TestCase
  test "validations" do
    school_type = build(:school_type, name: "")
    assert !school_type.valid?
    assert school_type.errors.include?(:name)
  end

  test "default scopes" do
    # The default scope should only return active school types
    create(:school_type, active: false)

    all_schoolTypes = SchoolType.all
    all_schoolTypes.each do |sc|
      assert_equal true, sc.active
    end
  end

  test "active scopes" do
    create(:school_type, active: true)
    create(:school_type, active: false)

    all_active = SchoolType.active
    assert all_active.size > 0

    all_active.each do |sc|
      assert_equal true,  sc.active
    end

    all_inactive = SchoolType.inactive
    all_inactive.each do |sc|
      assert_equal false,  sc.active
    end

    # Since all only returns active
    assert all_active.size + all_inactive.size > SchoolType.all.size

  end
end
