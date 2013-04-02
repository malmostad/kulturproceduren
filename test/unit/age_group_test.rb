require 'test_helper'

class AgeGroupTest < ActiveSupport::TestCase

  test "validations" do
    age_group = build(:age_group, :age => "a")
    assert !age_group.valid?
    assert_not_nil age_group.errors.on(:age)

    age_group = build(:age_group, :quantity => "a")
    assert !age_group.valid?
    assert_not_nil age_group.errors.on(:quantity)
  end

  test "with district" do
    district = create(:district_with_age_groups)
    create(:district_with_age_groups) # dummy

    age_groups = AgeGroup.with_district(district.id)
    assert !age_groups.blank?
    age_groups.each do |ag|
      assert_equal district.id, ag.group.school.district_id
    end
  end
  test "with age" do
    create(:age_group, :age => 8,  :quantity => 20)
    create(:age_group, :age => 9,  :quantity => 20)
    create(:age_group, :age => 10, :quantity => 30)
    create(:age_group, :age => 11, :quantity => 30)

    age_groups = AgeGroup.with_age(9, 10)
    assert !age_groups.blank?
    age_groups.each do |age_group|
      assert age_group.age >= 9
      assert age_group.age <= 10
    end
  end
  test "active" do
    create(:group_with_age_groups, :active => true)
    create(:group_with_age_groups, :active => false)

    age_groups = AgeGroup.active
    assert !age_groups.blank?
    age_groups.each do |age_group|
      assert age_group.group.active
    end
  end

  test "number of children by district" do
    district_1 = create(:district_with_age_groups, :school_count => 2, :group_count => 2, :age_group_data => [[10, 10], [11, 20]])
    district_2 = create(:district_with_age_groups, :school_count => 3, :group_count => 3, :age_group_data => [[10, 5],  [11, 15]])

    counts = AgeGroup.num_children_per_district

    assert_equal 2*2*10 + 2*2*20, counts[district_1.id.to_s]
    assert_equal 3*3*5 + 3*3*15,  counts[district_2.id.to_s]
  end
  test "number of children by group" do
    group_1 = create(:group_with_age_groups, :age_group_data => [[10, 10], [11, 20]])
    group_2 = create(:group_with_age_groups, :age_group_data => [[10, 5],  [11, 15]])

    counts = AgeGroup.num_children_per_group

    assert_equal 10+20, counts[group_1.id]
    assert_equal 5+15,  counts[group_2.id]
  end
end
