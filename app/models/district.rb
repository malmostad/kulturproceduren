class District < ActiveRecord::Base
  has_many    :School
  has_many    :Ticket
  validates_presence_of :name
  validates_associated  :School, :Ticket
end
