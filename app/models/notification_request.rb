class NotificationRequest < ActiveRecord::Base
  belongs_to  :Occasion
  belongs_to  :Group
end
