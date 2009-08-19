# Model for a bookable ticket.
#
# A ticket can be in several states:
#
#  * Unbooked, created and assigned to a group/district/free for all, but not booked.
#  * Booked, when the ticket is booked to an occasion.
#  * Used, when the ticket has been used for a person attending the occasion.
#  * Not used, when the ticket was not used on the occasion.
class Ticket < ActiveRecord::Base
  #State Declarations, "constants"

  UNBOOKED = 0
  BOOKED = 1
  USED = 2
  NOT_USED = 3

  belongs_to :occasion
  belongs_to :event
  belongs_to :district
  belongs_to :group
  belongs_to :companion
  belongs_to :user
end
