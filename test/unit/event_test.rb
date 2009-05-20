require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "find without tickets" do
    es = Event.without_tickets.find :all

    es.each { |e| assert e.tickets.empty? }
  end
end
