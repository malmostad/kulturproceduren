require 'test_helper'

class AgeGroupTest < ActiveSupport::TestCase

  test "with district" do
    AgeGroup.with_district([districts(:ost).id]).each do |ag|
      assert_equal districts(:ost).id, ag.group.school.district_id
    end
  end
  test "with age" do
    AgeGroup.with_age(9, 10).each do |ag|
      assert ag.age >= 9
      assert ag.age <= 10
    end
  end
  test "active" do
    AgeGroup.active.each do |ag|
      assert ag.group.active
    end
  end

  test "number of children by district" do
    counts = AgeGroup.with_age(9,9).num_children_per_district
    assert_equal 28, counts[districts(:centrum).id]
    assert_equal 21, counts[districts(:ost).id]
  end
  test "number of children by group" do
    counts = AgeGroup.with_age(11,11).num_children_per_group
    assert_equal 21, counts[groups(:centrumskolan1_klass35).id]
    assert_equal 7, counts[groups(:centrumskolan1_klass5spec).id]
    assert_equal 20, counts[groups(:centrumskolan2_klass5).id]
  end
end
