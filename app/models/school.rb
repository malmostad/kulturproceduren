# Model for schools. A schools belongs to a district and has many groups within it.
class School < ActiveRecord::Base
  
  has_many :groups, dependent: :destroy do
    def find_by_age_span(from, to)
      where("id in (select g.id from age_groups ag left join groups g on ag.group_id = g.id where age between ? and ? and g.active = ?)", from, to, true)
      .order(name: :asc)
    end
  end
  has_many :age_groups, through: :groups

  attr_accessible :name,
    :contacts,
    :elit_id,
    :district_id, :district,
    :extens_id

  belongs_to :district

  validates_presence_of :name,
    message: "Namnet får inte vara tomt"
  validates_presence_of :district,
    message: "Skolan måste tillhöra en stadsdel"

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets, :distribution_groups

  
  # Returns the number of available tickets on the given occasion for this school.
  def available_tickets_by_occasion(occasion)
    if occasion.is_a? Integer
      occasion = Occasion.where(id: occasion).first
      return nil if occasion.nil?
    end
    case occasion.event.ticket_state
    when :alloted_group
      self.groups.map{ |g| g.available_tickets_by_occasion(occasion) }.sum
    when :alloted_district
      Ticket.unbooked.where(event_id: occasion.event.id, district_id: self.district.id).count
    when :free_for_all
      Ticket.unbooked.where(event_id: occasion.event.id).count
    else
      0
    end
  end

  # Returns all schools that have groups that have tickets (alloted or booked) to
  # the given event.
  def self.find_with_tickets_to_event(event)
    self.includes(:district)
      .where("schools.id in (select g.school_id from tickets t left join groups g on g.id = t.group_id where t.event_id = ?)", event.id)
      .order("schools.name ASC")
  end

end
