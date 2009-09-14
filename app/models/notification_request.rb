# A notification request is a registration for users who wish to
# be notified when a specific group receives tickets for booking an occasion
# on a specific event. This class is used when transiting between
# ticket states on an event.
class NotificationRequest < ActiveRecord::Base
  belongs_to  :event
  belongs_to  :user
  belongs_to  :group

  # Finds all notification requests belonging to a specific group for a specific event.
  def self.find_by_event_and_group(event, group)
    find :all, :conditions => { :event_id => event.id, :group_id => group.id }
  end
end
