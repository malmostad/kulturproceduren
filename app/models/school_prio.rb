class SchoolPrio < ActiveRecord::Base
  belongs_to   :district
  belongs_to   :school

  def self.max_prio(district)
    maximum :prio, :conditions => { :district_id => district.id }
  end
end
