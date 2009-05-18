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
end
