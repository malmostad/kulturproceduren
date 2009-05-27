class District < ActiveRecord::Base
  
  has_many :schools, :dependent => :destroy do
    def find_by_age_span(from, to)
      find :all,
        :include => :school_prio,
        :order => "school_prios.prio ASC",
        :conditions => [ "schools.id in (select s.id from age_groups ag left join groups g on ag.group_id = g.id left join schools s on g.school_id = s.id  where age between ? and ?)", from, to ]
    end
  end

  has_many :tickets
  validates_presence_of :name
  validates_associated  :schools, :tickets
  has_and_belongs_to_many :users  #Role Culture Coordinator
  has_many    :school_prios

  attr_accessor :num_children, :num_tickets, :distribution_schools
end
