class Occasion < ActiveRecord::Base

  belongs_to :event
  has_many :tickets
  has_many :booking_requirements
  
  has_many :groups, :through => :tickets , :uniq => true
  belongs_to :answer

  validates_presence_of :date, :message => "Datumet får inte vara tom"
  validates_presence_of :address, :message => "Adressen får inte vara tom"
  
  validates_numericality_of :seats, :only_integer => true, :message => "Antalet platser måste vara ett giltigt heltal"

  def ticket_usage
    return [
      Ticket.count( :conditions => { :occasion_id => self.id } ) ,
      Ticket.count( :conditions => { :occasion_id => self.id  , :state => Ticket::BOOKED})
    ]
  end

  def self.search(filter, page)

    conditions = [ " current_date between events.visible_from and events.visible_to " ]

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
      conditions << from_date.advance(:days => 1)
    when :week
      conditions[0] << " and occasions.date <= ? "
      conditions << from_date.advance(:weeks => 1)
    when :month
      conditions[0] << " and occasions.date <= ? "
      conditions << from_date.advance(:months => 1)
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

    return paginate(
      :page => page,
      :conditions => conditions,
      :order => "occasions.date ASC, events.name ASC",
      :include => { :event => :culture_provider }
    )
  end

  def available_wheelchair_seats
    return self.wheelchair_seats - Ticket.count( :all , :conditions => { :occasion_id => self.id , :wheelchair => true , :state => Ticket::BOOKED})
 
  end
 
end