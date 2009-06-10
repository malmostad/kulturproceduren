require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "find without tickets" do
    es = Event.without_tickets.find :all

    es.each { |e| assert e.tickets.empty? }
  end

  test "bookable" do
    assert Event.find(events(:bookable).id).bookable?
    assert !Event.find(events(:not_bookable_by_date).id).bookable?
    assert !Event.find(events(:not_bookable_by_tickets).id).bookable?
  end

  test "not targeted group ids" do
    e = Event.find events(:with_groups_outside_age_span).id
    ids = e.not_targeted_group_ids

    assert_equal 1, ids.length
    assert_equal groups(:bar_bepa_klass_xb).id, ids[0]

    e = Event.find events(:wo_groups_outside_age_span).id
    ids = e.not_targeted_group_ids
    assert_equal 0, ids.length
  end
end
