# A group is the representation of a group of children in a school.
class Group < ActiveRecord::Base
  has_many :allotments, dependent: :nullify
  has_many :tickets, dependent: :destroy
  has_many :bookings, dependent: :destroy

  has_many :occasions, lambda{ distinct }, through: :tickets

  has_many :events, lambda{ distinct }, through: :tickets

  has_many(:age_groups, lambda{ order(age: :asc) }, dependent: :destroy) do
    # Returns the number of children in this group that is within the given age span
    def num_children_by_age_span(from, to)
      where("age BETWEEN ? AND ?", from, to).sum(:quantity)
    end
  end
  
  has_many :answer_forms, dependent: :destroy
  has_many :booking_requirements, dependent: :destroy do
    def for_occasion(occasion)
      where(occasion_id: occasion.id).first
    end
  end
  has_many :notification_requests, dependent: :destroy
  belongs_to :school

  attr_accessible :name,
    :contacts,
    :elit_id,
    :school_id, :school,
    :active,
    :priority,
    :extens_id
  
  validates_presence_of :name,
    message: "Namnet får inte vara tomt"
  validates_presence_of :school,
    message: "Gruppen måste tillhöra en skola"

  before_create :set_default_priority

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets
  

  # Returns the total number of children in this group.
  def total_children
    @total_children ||= age_groups.sum "quantity"
  end

  # Returns the number of tickets this group has booked on the given occasion. 
  def booked_tickets_by_occasion(occasion)
    occasion = Occasion.find(occasion) if occasion.is_a?(Integer)
    return Ticket.booked.where(group_id: self.id, occasion_id: occasion.id).count
  end

  # Returns the number of tickets with the given state available to this group on the given location.
  def available_tickets_by_occasion(occasion)
    occasion         = Occasion.find(occasion) if occasion.is_a?(Integer)
    existing_booking = self.booked_tickets_by_occasion(occasion) > 0
    tickets          = begin
      case occasion.event.ticket_state
      when :alloted_group then
        states = [:unbooked]
        states << :deactivated if existing_booking
        Ticket.with_states(states).where(event_id: occasion.event.id, group_id: self.id, wheelchair: false)
      when :alloted_district then
        Ticket.unbooked.where(event_id: occasion.event.id, district_id: self.school.district.id, wheelchair: false)
      when :free_for_all then
        Ticket.unbooked.where(event_id: occasion.event.id, wheelchair: false)
      end
    end
    available_seats = occasion.available_seats(existing_booking)
    return [available_seats, tickets.count].min
  end

  # Returns the bookable tickets this group has on the given occasion
  def bookable_tickets(occasion, lock = false)
    if occasion.is_a? Integer
      occasion = Occasion.where(id: occasion).first
      return nil if occasion.nil?
    end

    tickets = Ticket.where("true")
    case occasion.event.ticket_state
    when :alloted_group
      tickets = tickets.with_states(:unbooked, :deactivated).where(event_id: occasion.event.id, group_id: self.id)
    when :alloted_district
      tickets = tickets.unbooked.where(event_id: occasion.event.id, district_id: self.school.district.id)
    when :free_for_all
      tickets = tickets.unbooked.where(event_id: occasion.event.id)
    end
    tickets = tickets.lock if lock
    tickets
  end


  def move_first_in_prio
    self.class.where("priority < (select priority from groups where id = ?)", self.id).update_all("priority = priority + 1")
    self.priority = 1
    save!
  end
  def move_last_in_prio
    self.class.where("priority > (select priority from groups where id = ?)", self.id).update_all("priority = priority - 1")
    self.priority = Group.count(:all)
    save!
  end

  def self.sort_ids_by_priority(ids)
    connection.select_values(sanitize_sql_array(["select id from groups where id in (?) order by priority asc", ids]))
  end

  private

  def set_default_priority
    self.priority = Group.count(:all) + 1
  end

end
