# A model for the prioritization of schools within a district.
#
# The priority is used when doing the allotment of tickets to schools.
# Tickets are alloted according to priority, and when a school has been
# alloted tickets, it moves to the bottom of the priority list, ensuring
# a fair distribution of tickets.
class SchoolPrio < ActiveRecord::Base
  belongs_to :district
  belongs_to :school

  # Returns the lowest used priority in the given district
  def self.lowest_prio(district)
    maximum(:prio, :conditions => { :district_id => district.id }) || 0
  end

  # Returns the highest used priority in the given district
  def self.highest_prio(district)
    minimum(:prio, :conditions => { :district_id => district.id }) || 0
  end
end
