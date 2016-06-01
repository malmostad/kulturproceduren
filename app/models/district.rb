# A district contains multiple schools.
class District < ActiveRecord::Base

  has_paper_trail

  belongs_to :school_type

  has_many(:schools, lambda{ order "name ASC" }, dependent: :destroy) do

    # Finds all schools in the district that has children in the given age span.
    def find_by_age_span(from, to)
      where("schools.id in (select s.id from age_groups ag left join groups g on ag.group_id = g.id left join schools s on g.school_id = s.id  where age between ? and ? and g.active = ?)", from, to, true )
      .order("schools.name ASC")
    end
  end

  has_many :allotments, dependent: :nullify
  has_many :tickets

  has_and_belongs_to_many :users

  attr_accessible :name,
    :contacts,
    :elit_id,
    :extens_id,
    :school_type,
    :school_type_id

  validates_presence_of :name,
    message: "Namnet får inte vara tomt."
  validates_presence_of :school_type,
    message: "Området måste tillhöra en skoltyp."

  # Accessors for caching child and ticket amounts when doing the ticket allotment
  attr_accessor :num_children, :num_tickets, :distribution_schools
  attr_accessor :tot_children

  # Returns the number of avaliable tickets for the district in
  # the given occasion.
  #
  # When the occasion's event is in the free for all state, this
  # method returns the total amount of available tickets on the
  # event, otherwise only tickets associated with this district
  # is counted.
  def available_tickets_by_occasion(o)
    if o.is_a? Integer
      o = Occasion.where(id: o).first
      return nil if o.nil?
    end
    case o.event.ticket_state
    when :alloted_group, :alloted_school, :alloted_district
      # Count all tickets belonging to this district
      Ticket.unbooked.where(event_id: o.event.id, district_id: self.id).count
    when :free_for_all
      # Count all tickets
      Ticket.unbooked.where(event_id: o.event.id).count
    else
      0
    end
  end
end
