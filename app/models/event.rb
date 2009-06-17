class Event < ActiveRecord::Base

  named_scope :without_tickets, :conditions => 'id not in (select event_id from tickets)'
  named_scope :visible, :conditions => "current_date between visible_from and visible_to"

  has_many                :tickets, :dependent => :delete_all
  
  has_many                :districts, :through => :tickets, :uniq => true
  has_many                :groups, :through => :tickets, :uniq => true
  
  has_many                :occasions, :order => "date ASC"
  has_and_belongs_to_many :tags
  belongs_to              :culture_provider
  has_one                 :questionaire
  has_many                :images, :conditions => 'id != #{main_image_id || 0}'
  belongs_to              :main_image, :class_name => "Image", :dependent => :delete
  has_many                :notification_requests
  
  validates_presence_of :name, :from_age, :to_age, :description
  validates_numericality_of :from_age, :to_age, :only_integer => true

  # Ticket states

  CREATED          = 0
  ALLOTED_GROUP    = 1
  ALLOTED_DISTRICT = 2
  FREE_FOR_ALL     = 3
  NON_BOOKABLE     = 4


  def self.visible_events_by_userid(u)
    find :all,
      :conditions => [
      "current_date between events.visible_from and events.visible_to and id in (select distinct event_id from tickets,groups_users where user_id = ? and tickets.group_id = groups_users.group_id)",
      u ]
  end

  def last_occasion
    m = Occasion.new
    m.date = Date.new

    occasions.each do |o|
      if o.date > m.date
        m = o
      end
    end
    
    return m
  end

  def bookable?
    today = Date.today
    visible_from <= today && visible_to >= today && !tickets.empty?
  end

  def not_targeted_group_ids
    groups.find(:all,
      :select => "distinct groups.id",
      :conditions => [ "groups.id not in (select g.id from groups g left join age_groups ag on g.id = ag.group_id where ag.age between ? and ?)", from_age, to_age ]
    ).collect { |g| g.id.to_i }
  end
end
