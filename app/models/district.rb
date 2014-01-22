# -*- encoding : utf-8 -*-
# A district contains multiple schools.
class District < ActiveRecord::Base
  
  has_many :schools,
    :order => "name ASC",
    :dependent => :destroy do

    # Finds all schools in the district that has children in the given age span.
    def find_by_age_span(from, to)
      find :all,
        :order => "schools.name ASC",
        :conditions => [ "schools.id in (select s.id from age_groups ag left join groups g on ag.group_id = g.id left join schools s on g.school_id = s.id  where age between ? and ? and g.active = ?)", from, to, true ]
    end
  end

  has_many :allotments, :dependent => :nullify
  has_many :tickets

  has_and_belongs_to_many :users

  attr_accessible :name,
    :contacts,
    :elit_id,
    :extens_id

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt."

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets, :distribution_schools

  # Returns the number of avaliable tickets for the district in
  # the given occasion.
  #
  # When the occasion's event is in the free for all state, this
  # method returns the total amount of available tickets on the
  # event, otherwise only tickets associated with this district
  # is counted.
  def available_tickets_by_occasion(o)
    o = Occasion.find(o) if o.is_a?(Integer)
    return nil unless o.is_a?(Occasion)

    tickets = 0

    case o.event.ticket_state
    when :alloted_group, :alloted_district
      # Count all tickets belonging to this district
      tickets = Ticket.unbooked.count(
        :conditions => {
          :event_id => o.event.id,
          :district_id => self.id
        }
      )
    when :free_for_all
      # Count all tickets
      tickets = Ticket.unbooked.count(
        :conditions => { :event_id => o.event.id }
      )
    end

    return tickets
  end
end
