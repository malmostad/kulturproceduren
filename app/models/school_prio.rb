class SchoolPrio < ActiveRecord::Base
  belongs_to   :district
  belongs_to   :school

  def self.lowest_prio(district)
    maximum(:prio, :conditions => { :district_id => district.id }) || 0
  end

  def self.highest_prio(district)
    minimum(:prio, :conditions => { :district_id => district.id }) || 0
  end
end
