require 'test_helper'

class DistrictTest < ActiveSupport::TestCase

  test "schools by age span" do
    d = District.find districts(:bar)

    ss = d.schools.find_by_age_span(13, 14)

    assert !ss.empty?

    ss.each do |s|
      assert_equal d.id, s.district_id
      assert_equal schools(:bar_bepa_school).id, s.id
    end
  end
  
end
