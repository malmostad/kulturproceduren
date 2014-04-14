# A group is the representation of a group of children in a school.
class Group < ActiveRecord::Base
  has_many :allotments, :dependent => :nullify
  has_many :tickets, :dependent => :destroy
  has_many :bookings, :dependent => :destroy
  has_many :occasions, :through => :tickets , :uniq => true
  has_many :events, :through => :tickets , :uniq => true

  has_many :age_groups, :order => "age ASC", :dependent => :destroy do
    # Returns the number of children in this group that is within the given age span
    def num_children_by_age_span(from, to)
      sum "quantity", :conditions => [ "age between ? and ?", from, to ]
    end
  end
  
  has_many :answer_forms, :dependent => :destroy
  has_many :booking_requirements, :dependent => :destroy do
    def for_occasion(occasion)
      find :first, :conditions => { :occasion_id => occasion.id }
    end
  end
  has_many :notification_requests, :dependent => :destroy
  belongs_to :school
  
  validates_presence_of :name,
    :message => "Namnet får inte vara tomt"
  validates_presence_of :school,
    :message => "Gruppen måste tillhöra en skola"

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

    return Ticket.booked.count(
      :conditions => {
        :group_id => self.id,
        :occasion_id => occasion.id
      }
    )
  end

  # Returns the number of tickets with the given state available to this group on the given location.
  def available_tickets_by_occasion(occasion)
   
    occasion = Occasion.find(occasion) if occasion.is_a?(Integer)

    existing_booking = self.booked_tickets_by_occasion(occasion) > 0

    case occasion.event.ticket_state
    when :alloted_group then
      states = [:unbooked]
      states << :deactivated if existing_booking

      tickets = Ticket.with_states(states).count(
        :conditions => {
          :event_id => occasion.event.id,
          :group_id => self.id,
          :wheelchair => false
        }
      )

    when :alloted_district then
      tickets = Ticket.unbooked.count(
        :conditions => {
          :event_id => occasion.event.id,
          :district_id => self.school.district.id,
          :wheelchair => false
        }
      )
    when :free_for_all then
      tickets = Ticket.unbooked.count(
        :conditions => {
          :event_id => occasion.event.id,
          :wheelchair => false
        }  
      )
    end

    available_seats = occasion.available_seats(existing_booking)
    return ( available_seats > tickets ? tickets : available_seats )
  end

  # Returns the bookable tickets this group has on the given occasion
  def bookable_tickets(occasion, lock = false)
    
    if occasion.is_a?(Integer)
      occasion = Occasion.find(occasion) or return nil
    end

    tickets = []

    case occasion.event.ticket_state
    when :alloted_group
      tickets = Ticket.with_states(:unbooked, :deactivated).all(
        :conditions => {
          :event_id => occasion.event.id,
          :group_id => self.id
        },
        :lock => lock
      )
    when :alloted_district
      tickets = Ticket.unbooked.all(
        :conditions => {
          :event_id => occasion.event.id,
          :district_id => self.school.district.id
        },
        :lock => lock
      )
    when :free_for_all
      tickets = Ticket.unbooked.all(
        :conditions => {
          :event_id => occasion.event.id
        },
        :lock => lock
      )
    end

    return tickets
  end

  def move_first_in_prio
    Group.update_all(
      "priority = priority + 1",
      [ "priority < (select priority from groups where id = ?)", self.id ]
    )
    self.priority = 1
    save!
  end
  def move_last_in_prio
    Group.update_all(
      "priority = priority - 1",
      [ "priority > (select priority from groups where id = ?)", self.id ]
    )
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
