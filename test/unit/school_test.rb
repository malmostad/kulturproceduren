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
