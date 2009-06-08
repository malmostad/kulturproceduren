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
end
