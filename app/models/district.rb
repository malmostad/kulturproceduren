# A district contains multiple schools.
class District < ActiveRecord::Base
  
  has_many :schools,
    :order => "school_prios.prio ASC",
    :include => :school_prio,
    :dependent => :destroy do

    # Finds all schools in the district that has children in the given age span.
    def find_by_age_span(from, to)
      find :all,
        :include => :school_prio,
        :order => "school_prios.prio ASC",
        :conditions => [ "schools.id in (select s.id from age_groups ag left join groups g on ag.group_id = g.id left join schools s on g.school_id = s.id  where age between ? and ?)", from, to ]
    end
  end

  has_many :tickets
  has_many :school_prios

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt."

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets, :distribution_schools

  # Returns the number of avaliable tickets for the district in
  # the given occasion.
  #
  # When the occasion's event is in the free for all state, this
  # method returns the total amount of available tickets on the
  # event, otherwise only tickets associated with this district
  # is counted.
  def available_tickets_by_occasion(o)
    o = Occasion.find(o) if o.is_a?(Integer)
    return nil unless o.is_a?(Occasion)

    tickets = 0

    case o.event.ticket_state
    when Event::ALLOTED_GROUP, Event::ALLOTED_DISTRICT
      # Count all tickets belonging to this district
      tickets = Ticket.count(
        :conditions => {
          :event_id => o.event.id ,
          :district_id => self.id ,
          :state => Ticket::UNBOOKED
        }
      )
    when Event::FREE_FOR_ALL
      # Count all tickets
      tickets = Ticket.count(
        :conditions => {
          :event_id => o.event.id ,
          :state => Ticket::UNBOOKED
        }
      )
    end

    return tickets
  end
end
