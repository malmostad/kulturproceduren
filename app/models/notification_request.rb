# A notification request is a registration for users who wish to
# be notified when a specific group receives tickets for booking an occasion
# on a specific event. This class is used when transiting between
# ticket states on an event.
class NotificationRequest < ActiveRecord::Base
  belongs_to  :event
  belongs_to  :user
  belongs_to  :group
end
