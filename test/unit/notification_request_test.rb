require 'test_helper'

class NotificationRequestTest < ActiveSupport::TestCase
  test "find by event and group" do
    ns = NotificationRequest.find_by_event_and_group(events(:roda_cirkusen_group), groups(:ostskolan1_klass1))
    ns.each do |n|
      assert_equal events(:roda_cirkusen_group).id, n.event_id
      assert_equal groups(:ostskolan1_klass1).id, n.group_id
    end
  end

  test "find by event" do
    ns = NotificationRequest.find_by_event(events(:roda_cirkusen_group))
    ns.each do |n|
      assert_equal events(:roda_cirkusen_group).id, n.event_id
    end
  end

  test "find by event and districts" do
    ns = NotificationRequest.find_by_event_and_districts(events(:roda_cirkusen_group), [ districts(:ost) ])
    ns.each do |n|
      assert_equal events(:roda_cirkusen_group).id, n.event_id
      assert_equal districts(:ost).id, n.group.school.district_id
    end
  end
end
