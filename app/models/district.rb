class District < ActiveRecord::Base
  has_many    :School
  has_many    :Ticket
  validates_presence_of :name
  validates_associated  :School, :Ticket
  has_and_belongs_to_many :User  #Role Culture Coordinator
  has_many    :SchoolPrio
end
