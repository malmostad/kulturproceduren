# A culture event, possibly with bookable occasions.
#
# An event can be in in several states significant for the booking of tickets:
#
# * Alloted on a specific group so that only the group can book the tickets
# * Alloted on a specific district so that only groups in the district can book the tickets
# * Free for all so that all groups in the system can book the tickets
#
# The transition between the different states are done on a timed basis using a
# Rake task.
require 'uri'

class Event < ActiveRecord::Base
  before_save :correct_youtube_url

  # Scope for operating on standing events
  scope :standing, lambda{ where("events.id not in (select x.event_id from occasions x)") }

  # Scope for operating on non-standing events
  scope :non_standing, lambda{ where("events.id in (select x.event_id from occasions x)") }

  # Scope for operating on events without tickets
  scope :without_tickets, lambda{ where('id not in (select event_id from tickets)') }

  # Scope for operating on events that are visible
  scope :visible, lambda{ where("current_date between visible_from and visible_to") }

  # Scope for operating on events without questionnaires
  scope :without_questionnaires, lambda{ where('id not in (select event_id from questionnaires where event_id is not null)') }

  scope :not_linked_to_event, lambda{ |event|
    where("id not in (select to_id from event_links where from_id = ?)", event.id)
    .where("id != ?", event.id) 
  }
  scope :not_linked_to_culture_provider, lambda{ |culture_provider|
    where("id not in (select event_id from culture_providers_events where culture_provider_id = ?)", culture_provider.id)
  }

  has_many :allotments, lambda {
      includes(:district, group: :school)
      .order("districts.name asc nulls last")
      .order("schools.name asc nulls last")
      .order("groups.name asc nulls last") },
    dependent: :destroy

  has_many :tickets, dependent: :delete_all

  has_many :bookings, lambda{ distinct }, through: :tickets

  has_many :users, lambda{ distinct }, through: :tickets

  has_many :booked_users, lambda{ where("tickets.state = ?", Ticket::BOOKED).distinct },
    through: :tickets,
    source: :user
  
  has_many :districts, lambda{ distinct.order(name: :asc) }, through: :tickets
  

  has_many(:groups, lambda{ distinct.order("groups.name ASC") }, through: :tickets) do
    # Scope by district
    def find_by_district(district)
      includes(:school)
        .where('tickets.district_id = ?', district.id)
        .order("schools.name ASC, groups.name ASC")
    end
  end

  has_many(:schools, lambda{ distinct.order("schools.name ASC") }, through: :tickets) do
    # Scope by district
    def find_by_district(district)
      where('tickets.district_id = ?', district.id).order("schools.name ASC")
    end
  end

  has_many :unordered_groups, lambda{ distinct },
    through: :tickets,
    class_name: "Group",
    source: :group
  
  has_many :occasions, lambda{ order("date ASC, start_time ASC, stop_time ASC") }, dependent: :destroy
  has_many :reportable_occasions,
    lambda{ where("occasions.date <?", Date.today).order("date ASC, start_time ASC, stop_time ASC") },
    class_name: "Occasion"

  belongs_to :culture_provider

  has_and_belongs_to_many :categories, lambda{ includes(:category_group) }

  has_one :questionnaire, dependent: :destroy

  # All images
  has_many :images, dependent: :destroy
  

  # All images, excluding the main image (logotype)
  has_many :images_excluding_main,
    lambda{ |record| where("id != ?", record.main_image_id.to_i) },
    class_name: "Image"


  # The main image (logotype)
  belongs_to :main_image, class_name: "Image", dependent: :destroy

  has_many :attachments, lambda{ order "filename ASC" }, dependent: :destroy

  has_many :notification_requests, dependent: :destroy

  has_and_belongs_to_many :linked_events,
    lambda{ order "name ASC" },
    class_name: "Event",
    foreign_key: "from_id",
    association_foreign_key: "to_id",
    join_table: "event_links"
  has_and_belongs_to_many :linked_culture_providers,
    lambda{ order "name ASC" },
    class_name: "CultureProvider"

  has_and_belongs_to_many :school_types
  has_many :school_type_districts,
    through: :school_types,
    class_name: "District",
    source: :districts

  attr_accessible :name,
    :description,
    :visible_from,
    :visible_to,
    :is_age_range_used,
    :from_age,
    :to_age,
    :further_education,
    :ticket_release_date,
    :ticket_state,
    :url,
    :movie_url,
    :youtube_url,
    :opening_hours,
    :cost,
    :booking_info,
    :culture_provider_id,          :culture_provider,
    :main_image_id,                :main_image,
    :map_address,
    :single_group_per_occasion,
    :school_transition_date,
    :district_transition_date,
    :free_for_all_transition_date,
    :bus_booking,
    :last_bus_booking_date,
    :school_type_ids,
    :excluded_district_ids,
    :last_transitioned_date

  def is_age_range_used
    !(!self.from_age.nil? && self.from_age == -1 && !self.to_age.nil? && self.to_age == -1)
  end

  def is_age_range_used=(val)
    if val == false then
      self.from_age = -1
      self.to_age = -1
    end
  end

  validates_presence_of :name, message: "Namnet får inte vara tomt"
  validates_presence_of :description, message: "Beskrivningen får inte vara tom"
  validates_numericality_of :from_age, :to_age, only_integer: true, message: "Åldern måste vara ett giltigt heltal."
  validates_presence_of :visible_from, message: "Du måste ange datum"
  validates_presence_of :visible_to, message: "Du måste ange datum"

  before_save :set_further_education_age

  # Ticket states
  ALLOTED_GROUP    = 1
  ALLOTED_DISTRICT = 2
  FREE_FOR_ALL     = 3
  ALLOTED_SCHOOL   = 4
  FREE_FOR_ALL_WITH_EXCLUDED_DISTRICTS = 5

  def ticket_state
    case read_attribute(:ticket_state)
    when ALLOTED_GROUP
      :alloted_group
    when ALLOTED_SCHOOL
      :alloted_school
    when ALLOTED_DISTRICT
      :alloted_district
    when FREE_FOR_ALL_WITH_EXCLUDED_DISTRICTS
      :free_for_all_with_excluded_districts
    when FREE_FOR_ALL
      :free_for_all
    else
      nil
    end
  end
  def ticket_state=(value)
    case value
    when Symbol
      write_attribute(:ticket_state, self.class.ticket_state_id_from_symbol(value))
    when ALLOTED_GROUP..FREE_FOR_ALL
      write_attribute(:ticket_state, value)
    when ALLOTED_SCHOOL
      write_attribute(:ticket_state, value)
    when FREE_FOR_ALL_WITH_EXCLUDED_DISTRICTS
      write_attribute(:ticket_state, value)
    else
      write_attribute(:ticket_state, nil)
    end
  end

  def alloted_group?
    self.ticket_state == :alloted_group
  end
  def alloted_school?
    self.ticket_state == :alloted_school
  end
  def alloted_district?
    self.ticket_state == :alloted_district
  end
  def free_for_all_with_excluded_districts?
    self.ticket_state == :free_for_all_with_excluded_districts
  end
  def free_for_all?
    self.ticket_state == :free_for_all
  end

  # Transitioning
  def transition_to_school?
    !self.school_transition_date.blank? && self.alloted_group? && self.school_transition_date <= Date.today
  end
  def transition_to_school!
    self.ticket_state = :alloted_school
    self.save!
  end
  def transition_to_district?
     (
      (self.alloted_group? && self.school_transition_date.blank?) ||
      (self.alloted_school?)
     ) && !self.district_transition_date.blank? && self.district_transition_date <= Date.today
  end
  def transition_to_district!
    self.ticket_state = :alloted_district
    self.save!
  end
  def transition_to_free_for_all?
    (
      (self.alloted_group? && self.school_transition_date.blank? && district_transition_date.blank?) ||
      (self.alloted_school? && district_transition_date.blank?) ||
      (self.alloted_district?) ||
      (self.free_for_all_with_excluded_districts?)
    ) && !self.free_for_all_transition_date.blank? && self.free_for_all_transition_date <= Date.today
  end
  def transition_to_free_for_all!
    self.ticket_state = :free_for_all
    self.save!
  end


  # Indicates whether it is possible to book occasions belonging to this event.
  def bookable?(reload=false)
    if @is_bookable.nil? || reload
      today = Date.today
      @is_bookable = visible_from <= today && visible_to >= today && !ticket_release_date.nil? && ticket_release_date <= today && !tickets.empty? && !occasions.empty?
    end
    @is_bookable
  end
  # Indicates whether it is possible to report attendance globally on this event.
  def reportable?(reload=false)
    if @is_reportable.nil? || reload
      today = Date.today
      @is_reportable = visible_from <= today && !ticket_release_date.nil? && ticket_release_date <= today && !tickets.empty? && !occasions.empty?
    end
    @is_reportable
  end

  # Gets the ticket count grouped by groups
  def ticket_count_by_group
    tickets.group(:group_id).count
  end
  # Gets the ticket count grouped by districts
  def ticket_count_by_district
    tickets.group(:district_id).count
  end

  def has_booking?
    tickets.booked.exists?
  end

  def has_allotments?
    allotments.exists?
  end

  # Indicates whether the event has tickets available for booking
  def has_unbooked_tickets?(reload=false)
    if @has_unbooked_tickets.nil? || reload
      @has_unbooked_tickets = unbooked_tickets(reload) > 0
    end
    @has_unbooked_tickets
  end

  # Gets the total number of unbooked tickets on this event
  def unbooked_tickets(reload=false)
    if @total_unbooked_tickets.nil? || reload
      @total_unbooked_tickets = tickets.unbooked.count
    end
    @total_unbooked_tickets
  end

  def fully_booked?(reload=false)
    !has_unbooked_tickets?(reload) || !has_available_seats?
  end

  def has_available_seats?
    self.occasions.upcoming.any? { |o| o.available_seats > 0 }
  end

  # Returns an array of the ticket usage on this event. The first element is the
  # total number of tickets on the event, and the second is the number of tickets
  # that are booked.
  def ticket_usage
    [Ticket.where(event_id: self.id).count, Ticket.booked.where(event_id: self.id).count]
  end

  # Returns the ids of all groups that are not targeted by this event.
  def not_targeted_group_ids
    unordered_groups
      .select("groups.id")
      .where("groups.id not in (select g.id from groups g left join age_groups ag on g.id = ag.group_id where ag.age between ? and ?) or groups.active = ?", from_age, to_age, false )
      .order("groups.id ASC").map(&:id).map(&:to_i)
  end


  def bus_booking?
    self.bus_booking && self.last_bus_booking_date && Date.today <= self.last_bus_booking_date
  end
  def has_bus_bookings?
    bookings.any?(&:bus_booking)
  end


  # Search method for standing events. Returns a paginated result.
  #
  # Filters:
  # [<tt>:free_text</tt>] Free text search in the event's name and description
  # [<tt>:further_education</tt>] If <tt>true</tt>, the search should be restricted to events that are marked as further education
  # [<tt>:from_age</tt>] Sets a lower limit on the age of the returned events, not applicable if <tt>:further_education</tt> is set.
  # [<tt>:to_age</tt>] Sets an upper limit on the age of the returned events, not applicable if <tt>:further_education</tt> is set.
  # [<tt>:from_date</tt>] Sets a lower limit on the visibility of the returned events, defaults to the current date.
  # [<tt>:date_span</tt>] Sets a date span limit from <tt>from_date</tt>, can be <tt>:day</tt>, <tt>:week</tt>, <tt>:month</tt> and <tt>:date</tt>
  # [<tt>:to_age</tt>] If <tt>:date_span</tt> is <tt>:date</tt>, this value sets an upper limit on the visibility of the returned events.
  # [<tt>:categories</tt>] An array of the categories to limit the search to
  def self.search_standing(filter, page)
    # Standing events do not have occasions
    conditions = [ "events.id not in (select x.event_id from occasions x) and culture_providers.active = ? ", true ]

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
      conditions << from_date.advance(days: 1)
    when :week
      conditions[0] << " and events.visible_from <= ? "
      conditions << from_date.advance(weeks: 1)
    when :month
      conditions[0] << " and events.visible_from <= ? "
      conditions << from_date.advance(months: 1)
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

    #
    # Convert to scoped syntax
    # TODO: This method should be rewritten to make proper use of the scoped syntax
    #
    sql_fragment = conditions[0]
    variables    = conditions[1..-1]
    self.includes(:culture_provider)
      .references(:events, :culture_providers, :catagories_events)
      .where(sql_fragment, *variables)
      .order('events.visible_from ASC, events.name ASC')
      .paginate(page: page)
  end


  # Returns an array containg hashes with the stats in the following format:
  # [{event:, distict:, school:, group:, booked_tickets:,
  #   used_tickets_children:, used_tickets_adults:}]
  def get_visitor_stats_for_event
    return Event.get_visitor_stats_for_events([self])
  end


  # Returns an array containg hashes with the stats in the following format:
  # [{"event_id", "group_name", "school_name", "num_adult", "num_booked", "event_name", "num_children", "district_name"}]
  def self.get_visitor_stats_for_events(term , events = [])
    term, year = term.scan(/^(vt|ht)(20[01][0-9])$/).first

    if term == 'vt'
      from = "#{year}-01-01"
      to = "#{year}-06-30"
    else
      from = "#{year}-07-01"
      to = "#{year}-12-31"
    end

    event_ids = events.map { |e| e.id}.join(",")
    sql = "SELECT * FROM statistics( date '#{from}' , date '#{to}' )  WHERE event_id in ( #{event_ids} ) "
    puts "DEBUG_SQL: #{sql}"
    res = ActiveRecord::Base.connection.execute(sql)
    stats = res.collect
    return stats
  end


  protected

  def correct_youtube_url
    prefix = 'https://www.youtube.com/embed'
    if !self.youtube_url.blank?
      if self.youtube_url =~ /v=/i
        query_string = URI.parse(self.youtube_url).query
        parameters = Hash[URI.decode_www_form(query_string)]
        youtube_id = parameters['v']
        self.youtube_url = "#{prefix}/#{youtube_id}"
      else
        youtube_id = youtube_url.split('/').reject!(&:empty?).last
        if !youtube_id.blank?
          self.youtube_url = "#{prefix}/#{youtube_id}"
        end
      end
    end
  end

  # Removes the ages when the event has <tt>further_education</tt> set.
  def set_further_education_age
    if self.further_education
      self.from_age = -1
      self.to_age = -1
    end
  end

  private

  def self.ticket_state_id_from_symbol(sym)
    case sym
    when :alloted_group
      ALLOTED_GROUP
    when :alloted_school
      ALLOTED_SCHOOL
    when :alloted_district
      ALLOTED_DISTRICT
    when :free_for_all_with_excluded_districts
      FREE_FOR_ALL_WITH_EXCLUDED_DISTRICTS
    when :free_for_all
      FREE_FOR_ALL
    else
      nil
    end
  end
end
