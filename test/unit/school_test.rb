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

  test "successful below in prio" do
    s = School.find schools(:bar_bepa_school)
    assert_equal schools(:bar_apa_school).id, s.below_in_prio.id
  end

  test "successful above in prio" do
    s = School.find schools(:bar_bepa_school)
    assert_equal schools(:bar_cepa_school).id, s.above_in_prio.id
  end

    test "non existing below in prio" do
    s = School.find schools(:bar_apa_school)
    assert_nil s.below_in_prio
  end

  test "non existing above in prio" do
    s = School.find schools(:bar_cepa_school)
    assert_nil s.above_in_prio
  end
end
