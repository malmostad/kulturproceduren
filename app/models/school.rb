class School < ActiveRecord::Base
  
  has_many :groups, :dependent => :destroy do
    def find_by_age_span(from, to)
      find :all,
        :order => "name ASC",
        :conditions => [ "id in (select g.id from age_groups ag left join groups g on ag.group_id = g.id where age between ? and ?)", from, to ]
    end
  end

  belongs_to :district
  has_one :school_prio, :dependent => :destroy

  validates_presence_of  :name, :district_id

  attr_accessor :num_children, :num_tickets, :distribution_groups

  
  def above_in_prio
    prio = SchoolPrio.first :conditions => [ "district_id = ? and prio < ?", district_id, school_prio.prio ],
      :order => "prio DESC",
      :include => :school

    if prio
      return prio.school
    else
      return nil
    end
  end

  def below_in_prio
    prio = SchoolPrio.first :conditions => [ "district_id = ? and prio > ?", district_id, school_prio.prio ],
      :order => "prio ASC",
      :include => :school
    
    if prio
      return prio.school
    else
      return nil
    end
  end
end
