# A notification request is a registration for users who wish to
# be notified when a specific group receives tickets for booking a
# specific occasion. This class is used when transiting between
# ticket states on an event.
class NotificationRequest < ActiveRecord::Base
  belongs_to  :occasion
  belongs_to  :user
  belongs_to  :group
end
