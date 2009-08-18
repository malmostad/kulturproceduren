# A booking requirement is a container for a group's specific
# requirements when booking tickets for an occasion.
class BookingRequirement < ActiveRecord::Base
  belongs_to :group
  belongs_to :occasion
end 
