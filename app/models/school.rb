# Model for schools. A schools belongs to a district and has many groups within it.
class School < ActiveRecord::Base
  
  has_many :groups, :dependent => :destroy do
    def find_by_age_span(from, to)
      find :all,
        :order => "name ASC",
        :conditions => [ "id in (select g.id from age_groups ag left join groups g on ag.group_id = g.id where age between ? and ? and g.active = ?)", from, to, true ]
    end
  end
  has_many :age_groups, :through => :groups

  belongs_to :district

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt"
  validates_presence_of :district,
    :message => "Skolan måste tillhöra en stadsdel"

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets, :distribution_groups

  
  # Returns the number of available tickets on the given occasion for this school.
  def available_tickets_by_occasion(occasion)
    occasion = Occasion.find(occasion) if occasion.is_a?(Integer)
    return nil unless occasion.is_a?(Occasion)

    num_tickets = 0
    case occasion.event.ticket_state
    when Event::ALLOTED_GROUP
      self.groups.each { |g| num_tickets += g.available_tickets_by_occasion(occasion) }
    when Event::ALLOTED_DISTRICT
      num_tickets =  Ticket.count(
        :conditions => {
          :event_id => occasion.event.id ,
          :district_id => self.district.id ,
          :state => Ticket::UNBOOKED
        }
      )
    when Event::FREE_FOR_ALL
      num_tickets = Ticket.count(
        :conditions => {
          :event_id => occasion.event.id ,
          :state => Ticket::UNBOOKED
        }
      )
    end

    return num_tickets
  end

  # Returns all schools that have groups that have tickets (alloted or booked) to
  # the given event.
  def self.find_with_tickets_to_event(event)
    find :all, :include => :district, :order => "schools.name ASC",
      :conditions => [
        "schools.id in (select g.school_id from tickets t left join groups g on g.id = t.group_id where t.event_id = ?)",
        event.id
    ]
  end

end
