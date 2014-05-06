# A notification request is a registration for users who wish to
# be notified when a specific group receives tickets for booking an occasion
# on a specific event. This class is used when transiting between
# ticket states on an event.
class NotificationRequest < ActiveRecord::Base
  belongs_to  :event
  belongs_to  :user
  belongs_to  :group

  attr_accessible :send_mail,
    :send_sms,
    :event_id, :event,
    :group_id, :group,
    :user_id,  :user,
    :target_cd

  as_enum :target, { for_transition: 1, for_unbooking: 2 }, slim: :class

  scope :for_transition, lambda{ where(target_cd: targets.for_transition) }
  scope :for_unbooking,  lambda{ where(target_cd: targets.for_unbooking) }

  # Finds all notification requests belonging to a specific group for a specific event.
  def self.find_by_event_and_group(event, group)
    self.where(event_id: event.id, group_id: group.id)
  end

  # Finds all notification requests for a specific event
  def self.find_by_event(event)
    self.where(event_id: event.id).includes(:user, :group, :event)
  end

  # Finds all notification requests for a specific event that belongs
  # to groups in specific districts
  def self.find_by_event_and_districts(event, districts)
    self.includes(:user, {group: :school}, :event)
      .where("event_id" => event.id, "schools.district_id" => districts.map(&:id))
  end

  def self.unbooking_for(user, event)
    self.where(user_id: user.id, event_id: event.id, target_cd: NotificationRequest.targets.for_unbooking).first
  end
end
