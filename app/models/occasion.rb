# An occasion is a specific occasion where an event is shown. An occasion can
# be booked if there are tickets available on the event.
class Occasion < ActiveRecord::Base

  belongs_to :event
  has_many :tickets
  has_many :bookings do
    def school_ordered
      active.includes(group: :school).order("schools.name ASC").order("groups.name ASC")
    end
  end

  has_many(:groups, lambda{ distinct }, through: :tickets)

  has_many :attending_groups,
    lambda{ includes(:school)
      .where("tickets.state != 0")
      .distinct
      .order("schools.name ASC")
      .order("groups.name ASC")
    },
    class_name: "Group",
    source: :group,
    through: :tickets
  
  has_many :users, lambda{ distinct }, through: :tickets

  belongs_to :answer

  attr_accessible :date,
    :start_time,
    :stop_time,
    :seats,
    :wheelchair_seats,
    :address,
    :description,
    :telecoil,
    :cancelled,
    :event_id,         :event,
    :map_address,
    :single_group

  validates_presence_of :date,
    message: "Datumet får inte vara tom"
  validates_presence_of :address,
    message: "Adressen får inte vara tom"
  validates_numericality_of :seats, only_integer: true,
    message: "Antalet platser måste vara ett giltigt heltal"

  scope :upcoming, lambda{
    where("date > :date or (date = :date and start_time > :time)", date: Date.today, time: Time.zone.now.strftime("%H:%M"))
  }

  # Returns an array of the ticket usage on this occasion. The first element
  # in the array contains the total amount of tickets on this occasion, and the
  # second the total amount of booked tickets on this occasion.
  def ticket_usage
    [Ticket.where(occasion_id: self.id).count, Ticket.booked.where(occasion_id: self.id).count]
  end

  # Search method for occasions. Returns a paginated result.
  #
  # Filters:
  # [<tt>:free_text</tt>] Free text search in the occasion's event's name and description
  # [<tt>:further_education</tt>] If true, the search should be restricted to events that are marked as further education
  # [<tt>:from_age</tt>] Sets a lower limit on the age of the returned events, not applicable if <tt>:further_education</tt> is set.
  # [<tt>:to_age</tt>] Sets an upper limit on the age of the returned events, not applicable if <tt>:further_education</tt> is set.
  # [<tt>:from_date</tt>] Sets a lower limit on the date of the returned occasions, defaults to the current date.
  # [<tt>:date_span</tt>] Sets a date span limit from <tt>from_date</tt>, can be <tt>:day</tt>, <tt>:week</tt>, <tt>:month</tt> and <tt>:date</tt>
  # [<tt>:to_age</tt>] If <tt>:date_span</tt> is <tt>:date</tt>, this value sets an upper limit on the date of the returned events.
  # [<tt>:categories</tt>] An array of the categories to limit the search to
  #
  # TODO: Rewrite to make better use of arel.
  #
  def self.search(filter, page)

    conditions = [ " current_date between events.visible_from and events.visible_to and occasions.cancelled = ? and culture_providers.active = ? ", false, true ]

    unless filter[:free_text].blank?
      conditions[0] << " and ( events.name ilike ? or events.description ilike ? ) "
      conditions << "%#{filter[:free_text]}%"
      conditions << "%#{filter[:free_text]}%"
    end

    if filter[:further_education]
      conditions[0] << " and events.further_education = ? "
      conditions << true
    else
      if (filter[:from_age] || -1) >= 0
        conditions[0] << " and events.to_age >= ? "
        conditions << filter[:from_age]
      end
      if (filter[:to_age] || -1) >= 0
        conditions[0] << " and events.from_age <= ? "
        conditions << filter[:to_age]
      end
    end

    from_date = Date.today
    
    unless filter[:from_date].blank?
      conditions[0] << " and occasions.date >= ? "
      conditions << filter[:from_date]
      from_date = filter[:from_date]
    else
      conditions[0] << " and occasions.date >= current_date "
    end

    case filter[:date_span]
    when :day
      conditions[0] << " and occasions.date < ? "
      conditions << from_date.advance(days: 1)
    when :week
      conditions[0] << " and occasions.date <= ? "
      conditions << from_date.advance(weeks: 1)
    when :month
      conditions[0] << " and occasions.date <= ? "
      conditions << from_date.advance(months: 1)
    when :date
      unless filter[:to_date].blank?
        conditions[0] << " and occasions.date <= ? "
        conditions << filter[:to_date]
      end
    end

    unless filter[:categories].blank?
      conditions[0] << " and events.id in ( select ce.event_id from categories_events ce where ce.category_id in (?) ) "
      conditions << filter[:categories]
    end

    # Convert to non-deprecated way of finding records
    where_fragment, variables = conditions[0], conditions[1..-1]
    self.includes(event: :culture_provider)
      .references(:events, :culture_providers)
      .where(where_fragment, *variables)
      .order("occasions.date ASC,occasions.start_time ASC, events.name ASC")
      .paginate(page: page)
  end



  # Returns the amount of available wheelchair seats on this occasion.
  def available_wheelchair_seats
    return self.wheelchair_seats.to_i - Ticket.count_wheelchair_by_occasion(self)
  end

  # Returns the amount of available seats on this occasion.
  def available_seats(ignore_single_group = false)
    states = [ :unbooked ]
    states << :deactivated if ignore_single_group

    used_tickets = self.tickets.without_states(states).count(:id)

    return 0 if !ignore_single_group && used_tickets > 0 && self.single_group
    return self.seats.to_i + self.wheelchair_seats.to_i - used_tickets
  end

  def bus_booking?
    self.event.bus_booking?
  end
 
end
