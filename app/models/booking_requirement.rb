class BookingRequirement < ActiveRecord::Base
  belongs_to   :group
  belongs_to   :occasion
end 
