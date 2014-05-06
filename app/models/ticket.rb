# Model for a bookable ticket.
#
# A ticket can be in several states:
#
# * Unbooked, created and assigned to a group/district/free for all, but not booked.
# * Booked, when the ticket is booked to an occasion.
# * Used, when the ticket has been used for a person attending the occasion.
# * Not used, when the ticket was not used on the occasion.
class Ticket < ActiveRecord::Base
  # Ticket states
  UNBOOKED = 0
  BOOKED = 1
  USED = 2
  NOT_USED = 3
  DEACTIVATED = -1

  belongs_to :occasion
  belongs_to :event
  belongs_to :district
  belongs_to :group
  belongs_to :user
  belongs_to :booking
  belongs_to :allotment

  attr_accessible :state,
    :adult,
    :wheelchair,
    :booked_when,
    :group_id,     :group,
    :event_id,     :event,
    :occasion_id,  :occasion,
    :district_id,  :district,
    :user_id,      :user,
    :booking_id,   :booking,
    :allotment_id, :allotment


  def state
    case read_attribute(:state)
    when BOOKED
      :booked
    when USED
      :used
    when NOT_USED
      :not_used
    when DEACTIVATED
      :deactivated
    else
      :unbooked
    end
  end
  def state=(value)
    case value
    when Symbol
      write_attribute(:state, self.class.state_id_from_symbol(value))
    when DEACTIVATED..NOT_USED
      write_attribute(:state, value)
    else
      write_attribute(:state, UNBOOKED)
    end
  end

  def unbooked?
    self.state == :unbooked
  end
  def booked?
    self.state == :booked
  end
  def used?
    self.state == :used
  end
  def not_used?
    self.state == :not_used
  end
  def deactivated?
    self.state == :deactivated
  end

  scope :with_states, lambda{ |*states|
    ids = states.flatten.collect{ |s| state_id_from_symbol(s) }
    where(state: ids)
  }

  scope :without_states, lambda { |*states|
    ids = states.flatten.collect { |s| state_id_from_symbol(s) }
    where.not("tickets.state" => ids)
  }
  
  def self.unbooked
    with_states(:unbooked)
  end
  def self.not_unbooked
    without_states(:unbooked)
  end
  def self.booked
    with_states(:booked)
  end
  def self.not_booked
    without_states(:booked)
  end
  def self.used
    with_states(:used)
  end
  def self.not_used
    with_states(:not_used)
  end
  def self.deactivated
    with_states(:deactivated)
  end
  def self.not_deactivated
    without_states(:deactivated)
  end


  # Unbooks a ticket
  def unbook!
    if !self.unbooked?
      self.state = :unbooked
      self.booking = nil
      self.user = nil
      self.occasion = nil
      self.wheelchair = false
      self.adult = false
      self.booked_when = nil

      self.save!
    end
  end


  # Counts the number of available wheelchair tickets booked on an occasion
  def self.count_wheelchair_by_occasion(occasion)
    with_states(:booked, :used, :not_used)
      .where(occasion_id: occasion.id, wheelchair: true)
      .count
  end

  # Returns all bookings a user has made, in a paged result
  def self.find_user_bookings(user, page)
    paginate_by_sql(
      [ "select t.group_id, t.occasion_id, t.user_id, count(t.id) as num_tickets
      from tickets t left join occasions o on t.occasion_id = o.id
      where t.user_id = ? and t.state != 0
      group by t.group_id, t.occasion_id, t.user_id, o.date
      order by o.date DESC",
      user.id
    ], page: page)
  end

  # Returns all bookings for an event
  def self.find_event_bookings(event_id, filter, page)
    sql_params = [ event_id ]

    sql = " select t.group_id, t.occasion_id, t.user_id, count(t.id) as num_tickets
      from tickets t left join groups g on t.group_id = g.id left join schools s on g.school_id = s.id "
    sql << " where t.event_id = ? and t.state != 0 "

    unless filter.blank?
      unless filter[:district_id].blank?
        sql << " and s.district_id = ? "
        sql_params << filter[:district_id]
      end
    end

    sql << " group by t.group_id, t.occasion_id, t.user_id, s.name, g.name
      order by s.name, g.name DESC " 

    paginate_by_sql( [ sql, *sql_params ], page: page)
  end

  # Returns all bookings for an occasion
  def self.find_occasion_bookings(occasion_id, filter, page)
    sql_params = [ occasion_id ]

    sql = " select t.group_id, t.occasion_id, t.user_id, count(t.id) as num_tickets
      from tickets t left join groups g on t.group_id = g.id left join schools s on g.school_id = s.id "
    sql << " where t.occasion_id = ? and t.state != 0 "

    unless filter.blank?
      unless filter[:district_id].blank?
        sql << " and s.district_id = ? "
        sql_params << filter[:district_id]
      end
    end

    sql << " group by t.group_id, t.occasion_id, t.user_id, s.name, g.name
      order by s.name, g.name DESC " 

    paginate_by_sql( [ sql, *sql_params ], page: page)
  end

  # Returns all bookings for a specific group, in a paged result
  def self.find_group_bookings(group, page)
    paginate_by_sql(
      [ "select t.group_id, t.occasion_id, t.user_id, count(t.id) as num_tickets
      from tickets t left join occasions o on t.occasion_id = o.id
      where t.group_id = ? and t.state != 0
      group by t.group_id, t.occasion_id, t.user_id, o.date
      order by o.date DESC",
      group.id
    ], page: page)
  end

  # Returns a group's booked tickets for an occasion
  def self.find_booked(group, occasion)
    with_states(:booked, :deactivated).where(group_id: group.id, occasion_id: occasion.id)
  end

  # Returns a group's tickets for an occasion that are not unbooked
  def self.find_not_unbooked(group, occasion)
    not_unbooked.where(group_id: group.id, occasion_id: occasion.id)
  end

  # Returns a group's booked tickets for an occasion of a given type
  def self.find_booked_by_type(group, occasion, type)
    conditions = {
      group_id: group.id,
      occasion_id: occasion.id,
      adult: false,
      wheelchair: false
    }
    conditions[type] = true if type != :normal
    booked.where(conditions)
  end

  # Counts a group's tickets for an occasion of a given type with the given
  # state
  def self.count_by_type_state(group, occasion, type, states = [ :booked, :used, :not_used ])
    conditions = {}.tap do |h|
      h[:group_id]    = group.id
      h[:occasion_id] = occasion.id
      h[:adult]       = false
      h[:wheelchair]  = false

      h[type] = true unless type == :normal
    end
    with_states(states).where(conditions).count
  end


  # Returns the group's booking count for a given occasion
  def self.booking(group, occasion)
    booking = {}
    booking[:normal] = count_by_type_state(group, occasion, :normal)
    booking[:adult] = count_by_type_state(group, occasion, :adult)
    booking[:wheelchair] = count_by_type_state(group, occasion, :wheelchair)
    return booking
  end

  # Returns the group's usage count for a given occasion
  def self.usage(group, occasion)
    usage = {}
    [ :normal, :adult, :wheelchair ].each do |type|
      num_reported = count_by_type_state(group, occasion, type, [ :used, :not_used ])
      if num_reported > 0
        usage[type] = count_by_type_state(group, occasion, type, :used)
      else
        usage[type] = nil
      end
    end
    return usage
  end


  private

  def self.state_id_from_symbol(sym)
    case sym
    when :booked
      BOOKED
    when :used
      USED
    when :not_used
      NOT_USED
    when :deactivated
      DEACTIVATED
    else
      UNBOOKED
    end
  end
end
