require 'test_helper'

class DistrictTest < ActiveSupport::TestCase

  test "schools by age span" do
    d = District.find districts(:centrum)

    ss = d.schools.find_by_age_span(10, 11)

    assert !ss.empty?

    ss.each do |s|
      assert_equal d.id, s.district_id
      assert schools(:centrumskolan1).id, s.id
    end
  end

  test "available tickets by occasion" do
    assert_equal 2, districts(:ost).available_tickets_by_occasion(occasions(:roda_cirkusen_group_past))
    assert_equal 0, districts(:syd).available_tickets_by_occasion(occasions(:roda_cirkusen_group_past))
    assert_equal 2, districts(:ost).available_tickets_by_occasion(occasions(:roda_cirkusen_ffa_past))
    assert_equal 2, districts(:syd).available_tickets_by_occasion(occasions(:roda_cirkusen_ffa_past))
  end

end
