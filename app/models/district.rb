class District < ActiveRecord::Base
  
  has_many :schools,
    :order => "school_prios.prio ASC",
    :include => :school_prio,
    :dependent => :destroy do
    def find_by_age_span(from, to)
      find :all,
        :include => :school_prio,
        :order => "school_prios.prio ASC",
        :conditions => [ "schools.id in (select s.id from age_groups ag left join groups g on ag.group_id = g.id left join schools s on g.school_id = s.id  where age between ? and ?)", from, to ]
    end
  end

  has_many :tickets
  has_and_belongs_to_many :users  #Role Culture Coordinator
  has_many    :school_prios

  validates_presence_of :name, :message => "Namnet får inte vara tomt."

  attr_accessor :num_children, :num_tickets, :distribution_schools

  def available_tickets_by_occasion(o)
    if o.is_a? Integer
      o = Occasion.find(o)
    end
    unless o.is_a? Occasion
      return nil
    end
    retval = 0
    puts "District model - counting available tickets for district #{self.name}"
    case o.event.ticket_state
    when Event::ALLOTED_GROUP
      puts "Checking with condition district_id"
      retval =  Ticket.count(
        :conditions => {
          :event_id => o.event.id ,
          :district_id => self.id ,
          :state => Ticket::UNBOOKED
        }
      )
    when Event::ALLOTED_DISTRICT
      # Same as above ...
      puts "Checking with condition district_id"
      retval =  Ticket.count(
        :conditions => {
          :event_id => o.event.id ,
          :district_id => self.id ,
          :state => Ticket::UNBOOKED
        }
      )
    when Event::FREE_FOR_ALL
      puts "Checking without condition district_id"
      retval = Ticket.count(
        :conditions => {
          :event_id => o.event.id ,
          :state => Ticket::UNBOOKED
        }
      )
    end
    puts "Returning #{retval} tickets available"
    return retval
  end
end
