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

  # Finds all notification requests for a specific event
  def self.find_by_event(event)
    find :all, :conditions => { :event_id => event.id },
      :include => [ :user, :group, :event ]
  end

  # Finds all notification requests for a specific event that belongs
  # to groups in specific districts
  def self.find_by_event_and_districts(event, districts)
    find :all,
      :conditions => [
        "event_id = ? and schools.district_id in (?)",
        event.id,
        districts.collect { |d| d.id }
    ],
      :include => [ :user, { :group => :school }, :event ]
  end
end
