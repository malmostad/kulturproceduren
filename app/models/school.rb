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

  validates_presence_of  :name, :message => "Namnet får inte vara tomt"
  validates_presence_of  :district_id, :message => "Skolan måste tillhöra en stadsdel"

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

  def has_highest_prio?
    school_prio.prio == SchoolPrio.highest_prio(district)
  end

  def has_lowest_prio?
    school_prio.prio == SchoolPrio.lowest_prio(district)
  end

  def move_first_in_prio
    return if has_highest_prio?

    highest = SchoolPrio.highest_prio district
    SchoolPrio.update_all "prio = prio + 1",
      [ "district_id = ? and prio < ?", district.id, school_prio.prio ]

    school_prio.prio = highest
    school_prio.save!
  end

  def move_last_in_prio
    return if has_lowest_prio?

    lowest = SchoolPrio.lowest_prio district
    SchoolPrio.update_all "prio = prio - 1",
      [ "district_id = ? and prio > ?", district.id, school_prio.prio ]

    school_prio.prio = lowest
    school_prio.save!
  end

  def available_tickets_by_occasion(o)
    if o.is_a? Integer
      o = Occasion.find(o)
    end
    unless o.is_a? Occasion
      return nil
    end
    retval = 0
    case o.event.ticket_state
    when Event::ALLOTED_GROUP
      self.groups.each { |g| retval += g.available_tickets_by_occasion(o) }
    when Event::ALLOTED_DISTRICT
      retval =  Ticket.count(
        :conditions => {
          :event_id => o.event.id ,
          :district_id => self.district.id ,
          :state => Ticket::UNBOOKED
        }
      )
    when Event::FREE_FOR_ALL
      retval = Ticket.count(
        :conditions => {
          :event_id => o.event.id ,
          :state => Ticket::UNBOOKED
        }
      )
    end
    puts "Schools#available_tickets_by_occasion returning retval = #{retval}"
    return retval
  end
  
end
