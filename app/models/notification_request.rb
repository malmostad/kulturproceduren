class NotificationRequest < ActiveRecord::Base
  belongs_to  :occasion
  belongs_to  :group
end
