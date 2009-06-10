require 'test_helper'

class SchoolTest < ActiveSupport::TestCase

  test "groups by age span" do
    s = School.find schools(:bar_bepa_school)

    gs = s.groups.find_by_age_span(13, 14)

    assert !gs.empty?

    gs.each do |g|
      assert_equal s.id, g.school_id
      assert_equal groups(:bar_bepa_klass_xb).id, g.id
    end
  end

  
  test "below in prio" do
    s = School.find schools(:fp2)
    assert_equal schools(:fp3).id, s.below_in_prio.id

    s = School.find schools(:fp5)
    assert_nil s.below_in_prio
  end

  test "above in prio" do
    s = School.find schools(:fp3)
    assert_equal schools(:fp2).id, s.above_in_prio.id

    s = School.find schools(:fp1)
    assert_nil s.above_in_prio
  end

  test "has highest prio" do
    assert School.find(schools(:fp1)).has_highest_prio?
    assert !School.find(schools(:fp2)).has_highest_prio?
  end

  test "has lowest prio" do
    assert School.find(schools(:fp5)).has_lowest_prio?
    assert !School.find(schools(:fp4)).has_lowest_prio?
  end

  test "move first in prio" do
    s3 = School.find schools(:fp3)
    s3.move_first_in_prio

    assert_equal SchoolPrio.highest_prio(districts(:for_prio_testing)), s3.school_prio.prio
    assert_equal SchoolPrio.highest_prio(districts(:for_prio_testing)) + 1, School.find(schools(:fp1)).school_prio.prio
    assert_equal SchoolPrio.highest_prio(districts(:for_prio_testing)) + 2, School.find(schools(:fp2)).school_prio.prio
  end

  test "move last in prio" do
    s3 = School.find schools(:fp3)
    s3.move_last_in_prio

    assert_equal SchoolPrio.lowest_prio(districts(:for_prio_testing)), s3.school_prio.prio
    assert_equal SchoolPrio.lowest_prio(districts(:for_prio_testing)) - 1, School.find(schools(:fp5)).school_prio.prio
    assert_equal SchoolPrio.lowest_prio(districts(:for_prio_testing)) - 2, School.find(schools(:fp4)).school_prio.prio
  end
end
