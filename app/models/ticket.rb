class Ticket < ActiveRecord::Base
  #State Declarations, "constants"

  CREATED          = 0
  ALLOTED_GROUPS   = 1
  ALLOTED_DISTRICT = 2
  FREE_FOR_ALL     = 3
  BOOKED           = 4
  USED             = 5
  NOT_USED         = 6

  belongs_to :occasion
  belongs_to :event
  belongs_to :district
  belongs_to :group
end
