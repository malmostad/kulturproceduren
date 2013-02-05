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


  # Unbooks a ticket
  def unbook!
    if self.state != Ticket::UNBOOKED
      self.state = Ticket::UNBOOKED
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
    count :all, :conditions => {
      :occasion_id => occasion.id ,
      :wheelchair => true,
      :state => [ Ticket::BOOKED, Ticket::USED, Ticket::NOT_USED ]
    }
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
    ], :page => page)
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

    paginate_by_sql( [ sql, *sql_params ], :page => page)
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

    paginate_by_sql( [ sql, *sql_params ], :page => page)
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
    ], :page => page)
  end

  # Returns a group's booked tickets for an occasion
  def self.find_booked(group, occasion)
    find :all, :conditions => {
      :group_id => group.id,
      :occasion_id => occasion.id,
      :state => [Ticket::BOOKED, Ticket::DEACTIVATED]
    }
  end

  # Returns a group's tickets for an occasion that are not unbooked
  def self.find_not_unbooked(group, occasion)
    find :all, :conditions => [
      "group_id = ? and occasion_id = ? and state != ?",
      group.id,
      occasion.id,
      Ticket::UNBOOKED
    ]
  end

  # Returns a group's booked tickets for an occasion of a given type
  def self.find_booked_by_type(group, occasion, type)
    conditions = {
      :group_id => group.id,
      :occasion_id => occasion.id,
      :adult => false,
      :wheelchair => false,
      :state => Ticket::BOOKED
    }

    conditions[type] = true if type != :normal

    find :all, :conditions => conditions
  end

  # Counts a group's tickets for an occasion of a given type with the given
  # state
  def self.count_by_type_state(group, occasion, type, states = [ Ticket::BOOKED, Ticket::USED, Ticket::NOT_USED ])
    conditions = {
      :group_id => group.id,
      :occasion_id => occasion.id,
      :adult => false,
      :wheelchair => false,
      :state => states
    }

    conditions[type] = true if type != :normal

    count :conditions => conditions
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
      num_reported = count_by_type_state(group, occasion, type, [ Ticket::USED, Ticket::NOT_USED ])
      if num_reported > 0
        usage[type] = count_by_type_state(group, occasion, type, Ticket::USED)
      else
        usage[type] = nil
      end
    end
    return usage
  end
end
