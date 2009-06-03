class Group < ActiveRecord::Base
  has_many                  :notification_requests
  has_many                  :tickets
  has_many :occasions, :through => :tickets , :uniq => true
  has_many :events, :through => :tickets , :uniq => true


  has_many                  :age_groups, :order => "age ASC", :dependent => :destroy do
    def num_children_by_age_span(from, to)
      sum "quantity", :conditions => [ "age between ? and ?", from, to ]
    end
  end
  
  has_many                  :answers
  has_many                  :booking_requirements
  has_and_belongs_to_many   :users #CultureAdministrator Role
  belongs_to                :school
  
  validates_presence_of     :name
  validates_associated      :school

  attr_accessor :num_children, :num_tickets


  def ntickets_by_occasion(o,state=Ticket::UNBOOKED)
    if o.is_a? Integer
      o = Occasion.find(o)
    end
    case o.event.ticket_state
    when Event::ALLOTED_GROUP then
      Ticket.count :all , :conditions => {
        :event_id => o.event.id,
        :group_id => self.id,
        :state => state
      }
    when Event::ALLOTED_DISTRICT then
      Ticket.count :all , :conditions => {
        :event_id => o.event.id,
        :district_id => self.school.district.id,
        :state => state
      }
    when Event::FREE_FOR_ALL then
        Ticket.count :all , :conditions => {
        :event_id => o.event.id,
        :state => state
      }  
    end
  end

  def bookings()
    Ticket.find(:all , :select => "distinct occasion_id" , :conditions => { :group_id => self.id , :state => Ticket::BOOKED } ).collect {|t| Occasion.find(t.occasion_id)}
  end

  def bookable_tickets(o,lock = false)
    if o.is_a? Integer
      o = Occasion.find(o) or return nil
    end
    puts "Inside mytickets"
    puts "group = #{self.id}"
    puts "occasion = #{o.id}"
    
    case o.event.ticket_state
    when Event::ALLOTED_GROUP then
      Ticket.find( :all , :conditions => {
        :event_id => o.event.id,
        :group_id => self.id,
        :state => Ticket::UNBOOKED
      } , :lock => lock )
    when Event::ALLOTED_DISTRICT then
      Ticket.find( :all , :conditions => {
        :event_id => o.event.id,
        :district_id => self.school.district.id,
        :state => Ticket::UNBOOKED
      } , :lock => true )
    when Event::FREE_FOR_ALL then
        Ticket.find( :all , :conditions => {
        :event_id => o.event.id,
        :state => Ticket::UNBOOKED
      } , :lock => lock )
    end
  end

end
