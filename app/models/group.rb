class Group < ActiveRecord::Base
  has_many                  :NotifcationRequest
  has_many                  :Ticket
  has_many                  :AgeGroup
  has_and_belongs_to_many   :CultureAdministrator
  belongs_to                :School
  validates_presence_of     :name
  validates_associated      :School
end
