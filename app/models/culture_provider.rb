class CultureProvider < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :events, :order => "show_date ASC"
  has_many :standing_events, :class_name => "Event",
    :conditions => "events.id not in (select x.event_id from occasions x) and show_date <= now()",
    :order => "name ASC"
  has_many :occasions, :through => :events
  has_many :upcoming_occasions, :through => :events, :source => :occasions,
    :conditions => "events.show_date <= now() and occasions.date >= now()",
    :order => "occasions.date ASC"

  validates_presence_of :name
end
