class NotificationRequest < ActiveRecord::Base

  belongs_to  :occasion
  belongs_to  :user
  belongs_to  :group
  
end
