class Event < ActiveRecord::Base

  named_scope :without_tickets, :conditions => 'id not in (select event_id from tickets)'
  named_scope :visible, :conditions => "current_date between visible_from and visible_to"
  named_scope :without_questionaires, :conditions => 'id not in (select event_id from questionaires)'

  has_many :tickets, :dependent => :delete_all
  
  has_many :districts, :through => :tickets, :uniq => true
  has_many :groups, :through => :tickets, :uniq => true
  
  has_many :occasions, :order => "date ASC"
  belongs_to :culture_provider

  has_and_belongs_to_many :categories, :include => :category_group

  has_one :questionaire

  has_many :images
  has_many :images_excluding_main, :class_name => "Image", :conditions => 'id != #{main_image_id || 0}'
  belongs_to :main_image, :class_name => "Image", :dependent => :delete
  
  validates_presence_of :name, :message => "Namnet får inte vara tomt"
  validates_presence_of :description, :message => "Beskrivningen får inte vara tom"
  validates_numericality_of :from_age, :to_age, :only_integer => true, :message => "Åldern måste vara ett giltigt heltal."
  validates_presence_of :visible_from , :message => "Du måste ange datum"
  validates_presence_of :visible_to , :message => "Du måste ange datum"

  # Ticket states
  CREATED          = 0
  ALLOTED_GROUP    = 1
  ALLOTED_DISTRICT = 2
  FREE_FOR_ALL     = 3
  NON_BOOKABLE     = 4


  def bookable?
    today = Date.today
    visible_from <= today && visible_to >= today && ticket_release_date <= today && !tickets.empty?
  end

  def ticket_usage
    return [
      Ticket.count( :conditions => { :event_id => self.id } ) ,
      Ticket.count( :conditions => { :event_id => self.id  , :state => Ticket::BOOKED})
    ]
  end

  def not_targeted_group_ids
    groups.find(:all,
      :select => "distinct groups.id",
      :conditions => [ "groups.id not in (select g.id from groups g left join age_groups ag on g.id = ag.group_id where ag.age between ? and ?)", from_age, to_age ]
    ).collect { |g| g.id.to_i }
  end


  def self.search_standing(filter, page)
    conditions = [ "events.id not in (select x.event_id from occasions x) " ]

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
