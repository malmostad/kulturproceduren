class BookingRequirement < ActiveRecord::Base
  belongs_to   :Group
  belongs_to   :Occasion
end 
