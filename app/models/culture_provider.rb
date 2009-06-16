class CultureProvider < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :events, :order => "visible_from ASC"
  has_many :images, :conditions => 'id != #{main_image_id || 0}'
  belongs_to :main_image, :class_name => "Image", :dependent => :delete
  
  has_many :standing_events, :class_name => "Event",
    :conditions => "events.id not in (select x.event_id from occasions x) and current_date between events.visible_from and events.visible_to",
    :order => "name ASC"
  has_many :occasions, :through => :events
  has_many :upcoming_occasions, :through => :events, :source => :occasions,
    :conditions => "current_date between events.visible_from and events.visible_to and occasions.date >= current_date",
    :order => "occasions.date ASC"

  validates_presence_of :name
end
