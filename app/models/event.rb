class Event < ActiveRecord::Base
  has_many   :Ticket
  has_many   :Occasion
  validates_presence_of :from_age, :to_age, :description
end
