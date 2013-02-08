# A notification request is a registration for users who wish to
# be notified when a specific group receives tickets for booking an occasion
# on a specific event. This class is used when transiting between
# ticket states on an event.
class NotificationRequest < ActiveRecord::Base
  belongs_to  :event
  belongs_to  :user
  belongs_to  :group

  as_enum :target, { :for_transition => 1, :for_unbooking => 2 }, :slim => :class

  named_scope :for_transition, :conditions => { :target_cd => targets.for_transition }
  named_scope :for_unbooking, :conditions => { :target_cd => targets.for_unbooking }

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

  def self.unbooking_for(user, event)
    first(:conditions => {
      :user_id => user.id,
      :event_id => event.id,
      :target_cd => NotificationRequest.targets.for_unbooking
    })
  end
end
