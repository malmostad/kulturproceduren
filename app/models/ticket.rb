class Ticket < ActiveRecord::Base
  belongs_to :Occasion
  belongs_to :Event
  belongs_to :District
  belongs_to :Group
end
