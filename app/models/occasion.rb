class Occasion < ActiveRecord::Base
  belongs_to              :Event
  has_many                :Ticket
  has_many                :BookingRequirement
  has_many                :NotificationRequest
#  has_many_through        :Group, :through => tickets
  validates_presence_of   :date, :seats, :address
end

