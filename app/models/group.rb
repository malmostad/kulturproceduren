class Group < ActiveRecord::Base
  has_many                  :NotifcationRequest
  has_many                  :Ticket
  has_many                  :AgeGroup
  has_many                  :Answer
  has_many                  :BookingRequirement
  has_and_belongs_to_many   :User #CultureAdministrator Role
  belongs_to                :School
  validates_presence_of     :name
  validates_associated      :School
end
