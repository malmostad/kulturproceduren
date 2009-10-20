require 'test_helper'

class SchoolTest < ActiveSupport::TestCase

  test "groups by age span" do
    s = School.find schools(:centrumskolan1)

    gs = s.groups.find_by_age_span(9, 10)

    assert !gs.empty?

    gs.each do |g|
      assert_equal s.id, g.school_id
      assert(groups(:centrumskolan1_klass35).id == g.id || groups(:centrumskolan1_klass3spec).id == g.id)
    end
  end

  
  test "below in prio" do
    s = School.find schools(:sydskolan4).id
    assert_equal schools(:sydskolan3).id, s.below_in_prio.id

    s = School.find schools(:sydskolan1).id
    assert_nil s.below_in_prio
  end

  test "above in prio" do
    s = School.find schools(:sydskolan1).id
    assert_equal schools(:sydskolan2).id, s.above_in_prio.id

    s = School.find schools(:sydskolan4).id
    assert_nil s.above_in_prio
  end

  test "has highest prio" do
    assert School.find(schools(:sydskolan4).id).has_highest_prio?
    assert !School.find(schools(:sydskolan2).id).has_highest_prio?
  end

  test "has lowest prio" do
    assert School.find(schools(:sydskolan1).id).has_lowest_prio?
    assert !School.find(schools(:sydskolan3).id).has_lowest_prio?
  end

  test "move first in prio" do
    s = School.find schools(:sydskolan2).id
    s.move_first_in_prio

    d = districts(:syd)

    assert_equal SchoolPrio.highest_prio(d), s.school_prio.prio
    assert_equal SchoolPrio.highest_prio(d) + 1, School.find(schools(:sydskolan4)).school_prio.prio
    assert_equal SchoolPrio.highest_prio(d) + 2, School.find(schools(:sydskolan3)).school_prio.prio
  end

  test "move last in prio" do
    s = School.find schools(:sydskolan3)
    s.move_last_in_prio

    d = districts(:syd)

    assert_equal SchoolPrio.lowest_prio(d), s.school_prio.prio
    assert_equal SchoolPrio.lowest_prio(d) - 1, School.find(schools(:sydskolan1)).school_prio.prio
    assert_equal SchoolPrio.lowest_prio(d) - 2, School.find(schools(:sydskolan2)).school_prio.prio
  end


  test "available tickets by occasion" do
    assert_equal 1, schools(:ostskolan1).available_tickets_by_occasion(occasions(:roda_cirkusen_group_past))
    assert_equal 0, schools(:sydskolan1).available_tickets_by_occasion(occasions(:roda_cirkusen_group_past))
    assert_equal 2, schools(:ostskolan1).available_tickets_by_occasion(occasions(:roda_cirkusen_district_past))
    assert_equal 2, schools(:ostskolan2).available_tickets_by_occasion(occasions(:roda_cirkusen_district_past))
    assert_equal 0, schools(:sydskolan1).available_tickets_by_occasion(occasions(:roda_cirkusen_district_past))
    assert_equal 2, schools(:ostskolan1).available_tickets_by_occasion(occasions(:roda_cirkusen_ffa_past))
    assert_equal 2, schools(:ostskolan2).available_tickets_by_occasion(occasions(:roda_cirkusen_ffa_past))
    assert_equal 2, schools(:sydskolan1).available_tickets_by_occasion(occasions(:roda_cirkusen_ffa_past))
  end

  test "find with tickets to events" do
    schools = School.find_with_tickets_to_event(events(:roda_cirkusen_group))
    assert_equal 2, schools.length
    assert schools[0].id == schools(:ostskolan1).id || schools[0].id == schools(:ostskolan2).id
    assert schools[1].id == schools(:ostskolan1).id || schools[1].id == schools(:ostskolan2).id
  end
  
end
