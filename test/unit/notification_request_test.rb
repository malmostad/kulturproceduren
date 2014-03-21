# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class NotificationRequestTest < ActiveSupport::TestCase
  test "for transition" do
    create_list(:notification_request, 4, :target_cd => 1)
    create_list(:notification_request, 4, :target_cd => 2)
    NotificationRequest.for_transition.each { |nr| assert nr.for_transition? }
  end
  test "for unbooking" do
    create_list(:notification_request, 4, :target_cd => 1)
    create_list(:notification_request, 4, :target_cd => 2)
    NotificationRequest.for_unbooking.each { |nr| assert nr.for_unbooking? }
  end
  test "find by event and group" do
    event = create(:event)
    group = create(:group)
    create_list(:notification_request, 4, :event => event, :group => group)
    create_list(:notification_request, 4,                  :group => group)
    create_list(:notification_request, 4, :event => event)
    create_list(:notification_request, 4)
    NotificationRequest.find_by_event_and_group(event, group).each { |nr| assert nr.event.id == event.id && nr.group.id == group.id }
  end

  test "find by event" do
    event = create(:event)
    create_list(:notification_request, 4, :event => event)
    create_list(:notification_request, 4)
    NotificationRequest.find_by_event(event).each { |nr| assert nr.event.id == event.id }
  end

  test "find by event and districts" do
    events = create_list(:event, 2)
    districts = create_list(:district, 3)
    districts.each do |d|
      create_list(:school, 3, :district => d) do |s|
        create_list(:group, 3, :school => s) do |g|
          events.each do |e|
            create_list(:notification_request, 3, :event => e, :group => g)
          end
        end
      end
    end

    ds = districts.first(2)
    NotificationRequest.find_by_event_and_districts(events.first, ds).each do |nr|
      assert nr.event.id == events.first.id && ds.collect(&:id).include?(nr.group.school.district.id)
    end
  end

  test "unbooking for" do
    users  = create_list(:user, 2)
    events = create_list(:event, 2)

    # Proper
    nr = create(:notification_request, :target_cd => 2, :user => users.first,  :event => events.first)
    create(:notification_request, :target_cd => 2, :user => users.first,  :event => events.second)
    create(:notification_request, :target_cd => 2, :user => users.second, :event => events.second)
    create(:notification_request, :target_cd => 2, :user => users.second, :event => events.first)

    # Dummies
    create(:notification_request, :user => users.first,   :event => events.first)
    create(:notification_request, :user => users.first,   :event => events.second)
    create(:notification_request, :user => users.second,  :event => events.second)
    create(:notification_request, :user => users.second,  :event => events.first)
    create(:notification_request, :user => users.first)
    create(:notification_request, :user => users.second)
    create(:notification_request, :event => events.first)
    create(:notification_request, :event => events.second)

    assert_equal nr.id, NotificationRequest.unbooking_for(users.first, events.first).id
  end
end
