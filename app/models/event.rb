# A culture event, possibly with bookable occasions.
#
# An event can be in in several states significant for the booking of tickets:
#
#  * Alloted on a specific group so that only the group can book the tickets
#  * Alloted on a specific district so that only groups in the district can book the tickets
#  * Free for all so that all groups in the system can book the tickets
#
# The transition between the different states are done on a timed basis using a
# Rake task.
class Event < ActiveRecord::Base

  # Scope for operating on events without tickets
  named_scope :without_tickets, :conditions => 'id not in (select event_id from tickets)'
  # Scope for operating on events that are visible
  named_scope :visible, :conditions => "current_date between visible_from and visible_to"
  # Scope for operating on events without questionnaires
  named_scope :without_questionaires, :conditions => 'id not in (select event_id from questionaires)'

  has_many :tickets, :dependent => :delete_all
  
  has_many :districts, :through => :tickets, :uniq => true
  has_many :groups, :through => :tickets, :uniq => true
  
  has_many :occasions, :order => "date ASC, start_time ASC, stop_time ASC"
  belongs_to :culture_provider

  has_and_belongs_to_many :categories, :include => :category_group

  has_one :questionaire

  # All images
  has_many :images
  # All images, excluding the main image (logotype)
  has_many :images_excluding_main, :class_name => "Image", :conditions => 'id != #{main_image_id || 0}'
  # The main image (logotype)
  belongs_to :main_image, :class_name => "Image", :dependent => :delete

  has_many :attachments, :order => "filename ASC"
  
  validates_presence_of :name,
    :message => "Namnet får inte vara tomt"
  validates_presence_of :description,
    :message => "Beskrivningen får inte vara tom"
  validates_numericality_of :from_age, :to_age, :only_integer => true,
    :message => "Åldern måste vara ett giltigt heltal."
  validates_presence_of :visible_from,
    :message => "Du måste ange datum"
  validates_presence_of :visible_to,
    :message => "Du måste ange datum"

  # Ticket states
  CREATED          = 0
  ALLOTED_GROUP    = 1
  ALLOTED_DISTRICT = 2
  FREE_FOR_ALL     = 3
  NON_BOOKABLE     = 4


  # Indicates whether it is possible to book occasions belonging to this event.
  def bookable?
    today = Date.today
    visible_from <= today && visible_to >= today && !ticket_release_date.nil? && ticket_release_date <= today && !tickets.empty?
  end

  # Returns an array of the ticket usage on this event. The first element is the
  # total number of tickets on the event, and the second is the number of tickets
  # that are booked.
  def ticket_usage
    return [
      Ticket.count( :conditions => { :event_id => self.id } ) ,
      Ticket.count( :conditions => { :event_id => self.id  , :state => Ticket::BOOKED})
    ]
  end

  # Returns the ids of all groups that are not targeted by this event.
  def not_targeted_group_ids
    groups.find(:all,
      :select => "distinct groups.id",
      :conditions => [ "groups.id not in (select g.id from groups g left join age_groups ag on g.id = ag.group_id where ag.age between ? and ?)", from_age, to_age ]
    ).collect { |g| g.id.to_i }
  end


  # Search method for standing events. Returns a paginated result.
  #
  # Filters:
  # [+:free_text+] Free text search in the event's name and description
  # [+:further_education+] If true, the search should be restricted to events that are marked as further education
  # [+:from_age+] Sets a lower limit on the age of the returned events, not applicable if +:further_education+ is set.
  # [+:to_age+] Sets an upper limit on the age of the returned events, not applicable if +:further_education+ is set.
  # [+:from_date+] Sets a lower limit on the visibility of the returned events, defaults to the current date.
  # [+:date_span+] Sets a date span limit from +from_date+, can be +:day+, +:week+, +:month+ and +:date+
  # [+:to_age+] If +:date_span+ is +:date+, this value sets an upper limit on the visibility of the returned events.
  # [+:categories+] An array of the categories to limit the search to
  def self.search_standing(filter, page)
    # Standing events do not have occasions
    conditions = [ "events.id not in (select x.event_id from occasions x) " ]

    # Free text condition
    unless filter[:free_text].blank?
      conditions[0] << " and ( events.name ilike ? or events.description ilike ? ) "
      conditions << "%#{filter[:free_text]}%"
      conditions << "%#{filter[:free_text]}%"
    end

    # Further education condition
    if filter[:further_education]
      conditions[0] << " and events.further_education = ? "
      conditions << true
    else
      # Age conditions
      if (filter[:from_age] || -1) >= 0
        conditions[0] << " and events.to_age >= ? "
        conditions << filter[:from_age]
      end
      if (filter[:to_age] || -1) >= 0
        conditions[0] << " and events.from_age <= ? "
        conditions << filter[:to_age]
      end
    end

    # The start date, defaults to today
    from_date = Date.today
    
    # Date conditions
    unless filter[:from_date].blank?
      conditions[0] << " and events.visible_to >= ?"
      conditions << filter[:from_date]
      from_date = filter[:from_date]
    else
      conditions[0] << " and events.visible_to >= current_date"
    end

    case filter[:date_span]
    when :day
      conditions[0] << " and events.visible_from <= ? "
      conditions << from_date.advance(:days => 1)
    when :week
      conditions[0] << " and events.visible_from <= ? "
      conditions << from_date.advance(:weeks => 1)
    when :month
      conditions[0] << " and events.visible_from <= ? "
      conditions << from_date.advance(:months => 1)
    when :date
      unless filter[:to_date].blank?
        conditions[0] << " and events.visible_from <= ? "
        conditions << filter[:to_date]
      end
    end

    # Category conditions
    unless filter[:categories].blank?
      conditions[0] << " and events.id in ( select ce.event_id from categories_events ce where ce.category_id in (?) ) "
      conditions << filter[:categories]
    end

    return paginate(
      :page => page,
      :conditions => conditions,
      :order => 'events.visible_from ASC, events.name ASC',
      :include => :culture_provider
    )
  end
end
