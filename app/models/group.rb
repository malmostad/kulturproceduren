# A group is the representation of a group of children in a school.
class Group < ActiveRecord::Base
  has_many :tickets
  has_many :occasions, :through => :tickets , :uniq => true
  has_many :events, :through => :tickets , :uniq => true

  has_many :age_groups, :order => "age ASC", :dependent => :destroy do
    # Returns the number of children in this group that is within the given age span
    def num_children_by_age_span(from, to)
      sum "quantity", :conditions => [ "age between ? and ?", from, to ]
    end
  end
  
  has_many :answers
  has_many :booking_requirements
  belongs_to :school
  
  validates_presence_of :name,
    :message => "Namnet får inte vara tomt"
  validates_associated :school,
    :message => "Gruppen måste tillhöra en skola"

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets
  

  # Returns the total number of children in this group.
  def total_children
    @total_children ||= age_groups.sum "quantity"
  end

  # Returns the companion that will accompany this group to the given occasion.
  def companion_by_occasion(occasion)
    Ticket.find(:first , :conditions => {
        :group_id => id ,
        :occasion_id => occasion.id ,
        :state => Ticket::BOOKED
      }).companion
  end

  # Returns the number of tickets this group has booked on the given occasion. 
  def booked_tickets_by_occasion(occasion)
    occasion = Occasion.find(occasion) if occasion.is_a?(Integer)

    return Ticket.count(:all,
      :conditions => {
        :group_id => self.id ,
        :occasion_id => occasion.id ,
        :state => Ticket::BOOKED
      })
  end

  # Returns the number of tickets with the given state available to this group on the given location.
  def available_tickets_by_occasion(occasion, state = Ticket::UNBOOKED, wheelchair = false)
   
    occasion = Occasion.find(occasion) if occasion.is_a?(Integer)

    case occasion.event.ticket_state
    when Event::ALLOTED_GROUP then
      n = Ticket.count :all , :conditions => {
        :event_id => occasion.event.id,
        :group_id => self.id,
        :state => state ,
        :wheelchair => wheelchair
      }
    when Event::ALLOTED_DISTRICT then
      n = Ticket.count :all , :conditions => {
        :event_id => occasion.event.id,
        :district_id => self.school.district.id,
        :state => state ,
        :wheelchair => wheelchair
      }
    when Event::FREE_FOR_ALL then
      n = Ticket.count :all , :conditions => {
        :event_id => occasion.event.id,
        :state => state ,
        :wheelchair => wheelchair
      }  
    end

    if state == Ticket::UNBOOKED
      m = occasion.seats - Ticket.count(:conditions => { :occasion_id => occasion.id , :state => Ticket::BOOKED } )
      return ( m > n ? n : m )
    else
      return n
    end
  end

  # Returns the bookable tickets this group has on the given occasion
  def bookable_tickets(occasion, lock = false)
    
    if occasion.is_a?(Integer)
      occasion = Occasion.find(occasion) or return nil
    end

    tickets = []

    case occasion.event.ticket_state
    when Event::ALLOTED_GROUP
      tickets = Ticket.find( :all , :conditions => {
          :event_id => occasion.event.id,
          :group_id => self.id,
          :state => Ticket::UNBOOKED
        } , :lock => lock )
    when Event::ALLOTED_DISTRICT
      tickets = Ticket.find( :all , :conditions => {
          :event_id => occasion.event.id,
          :district_id => self.school.district.id,
          :state => Ticket::UNBOOKED
        }, :lock => lock )
    when Event::FREE_FOR_ALL
      tickets = Ticket.find( :all , :conditions => {
          :event_id => occasion.event.id,
          :state => Ticket::UNBOOKED
        }, :lock => lock )
    end

    return tickets
  end

end
