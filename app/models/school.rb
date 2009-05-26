class School < ActiveRecord::Base
  
  has_many :groups do
    def find_by_age_span(from, to)
      find :all,
        :order => "name ASC",
        :conditions => [ "id in (select g.id from age_groups ag left join groups g on ag.group_id = g.id where age between ? and ?)", from, to ]
    end
  end

  belongs_to :district
  has_one :school_prio

  validates_presence_of  :name, :district_id
  validates_associated   :districts, :groups

  attr_accessor :num_children, :num_tickets, :distribution_groups
end
