class Ticket < ActiveRecord::Base
  #State Declarations, "constants"

  CREATED          = 0
  ALLOTED_GROUPS   = 1
  ALLOTED_DISTRICT = 2
  FREE_FOR_ALL     = 3
  BOOKED           = 4
  USED             = 5
  NOT_USED         = 6

  belongs_to :Occasion
  belongs_to :Event
  belongs_to :District
  belongs_to :Group
end
