# Model for schools. A schools belongs to a district and has many groups within it.
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

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt"
  validates_presence_of :district_id,
    :message => "Skolan måste tillhöra en stadsdel"

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets, :distribution_groups

  
  # Finds the school that is directly above this school in priority. Returns +nil+ if
  # this school is the top prioritized school.
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

  # Finds the school that is directly below this school in priority. Returns +nil+ if
  # this school is the bottom prioritized school.
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

  # Returns true if this school has the highest priority in its district.
  def has_highest_prio?
    school_prio.prio == SchoolPrio.highest_prio(district)
  end

  # Returns true if this school has the lowest priority in its district.
  def has_lowest_prio?
    school_prio.prio == SchoolPrio.lowest_prio(district)
  end

  # Moves this school to the top of the priority list in its district.
  def move_first_in_prio
    return if has_highest_prio?

    highest = SchoolPrio.highest_prio district
    SchoolPrio.update_all "prio = prio + 1",
      [ "district_id = ? and prio < ?", district.id, school_prio.prio ]

    school_prio.prio = highest
    school_prio.save!
  end

  # Moves this school to the bottom of the priority list in its district.
  def move_last_in_prio
    return if has_lowest_prio?

    lowest = SchoolPrio.lowest_prio district
    SchoolPrio.update_all "prio = prio - 1",
      [ "district_id = ? and prio > ?", district.id, school_prio.prio ]

    school_prio.prio = lowest
    school_prio.save!
  end

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
