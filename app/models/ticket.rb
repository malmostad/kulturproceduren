class Ticket < ActiveRecord::Base
  #State Declarations, "constants"

  UNBOOKED         = 0
  BOOKED           = 1
  USED             = 2
  NOT_USED         = 3


  belongs_to :occasion
  belongs_to :event
  belongs_to :district
  belongs_to :group
  belongs_to :companion
  belongs_to :user

end
