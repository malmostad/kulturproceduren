# A culture provider is an arranger of events.
#
# The culture provider has additional information about it,
# for display on a presentation page in the UI.
class CultureProvider < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :events, :order => "visible_from ASC"

  # All images
  has_many :images
  # All images, excluding the main image (logotype)
  has_many :images_excluding_main, :class_name => "Image",
    :conditions => 'id != #{main_image_id || 0}'
  # The main image (logotype)
  belongs_to :main_image, :class_name => "Image", :dependent => :delete
  
  # Standing events - Events without occasions
  has_many :standing_events, :class_name => "Event",
    :conditions => "events.id not in (select x.event_id from occasions x) and current_date between events.visible_from and events.visible_to",
    :order => "name ASC"
  has_many :occasions, :through => :events
  has_many :upcoming_occasions, :through => :events, :source => :occasions,
    :conditions => "current_date between events.visible_from and events.visible_to and occasions.date >= current_date",
    :order => "occasions.date ASC"

  has_and_belongs_to_many :linked_culture_providers,
    :class_name => "CultureProvider",
    :foreign_key => "from_id",
    :association_foreign_key => "to_id",
    :order => "name ASC",
    :join_table => "culture_provider_links"
  has_and_belongs_to_many :linked_events,
    :class_name => "Event",
    :order => "name ASC"

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt."

  default_scope :order => 'name ASC'

  named_scope :not_linked_to_culture_provider, lambda { |culture_provider|
    { :conditions => [ "id not in (select to_id from culture_provider_links where from_id = ?) and id != ?", culture_provider.id, culture_provider.id ] }
  }
  named_scope :not_linked_to_event, lambda { |event|
    { :conditions => [ "id not in (select culture_provider_id from culture_providers_events where event_id = ?) and id != ?", event.id, event.culture_provider_id ] }
  }
end
