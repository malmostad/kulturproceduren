# -*- encoding : utf-8 -*-
# A culture provider is an arranger of events.
#
# The culture provider has additional information about it,
# for display on a presentation page in the UI.
class CultureProvider < ActiveRecord::Base
  
  has_and_belongs_to_many :users

  has_many :events, lambda{ order("events.visible_from ASC") }

  # All images
  has_many :images
  
  # All images, excluding the main image (logotype)
  has_many :images_excluding_main,
    lambda{ |record| where("id != ?", record.main_image_id.to_i) },
    :class_name => "Image"

  #has_many :images_excluding_main,:class_name => "Image",
  #  :conditions => proc { [ "id != ?", self.main_image_id || 0 ] }
  

  # The main image (logotype)
  belongs_to :main_image, :class_name => "Image", :dependent => :delete
  
  # Standing events - Events without occasions
  has_many :standing_events, lambda {
      where("events.id NOT IN (select x.event_id from occasions x)")
      .where("CURRENT_DATE BETWEEN events.visible_from AND events.visible_to")
      .order(name: :asc)
    },
    :class_name => "Event"

  has_many :occasions, :through => :events

  has_many :upcoming_occasions, lambda{
      where("CURRENT_DATE BETWEEN events.visible_from AND events.visible_to")
      .where("occasions.date >= CURRENT_DATE")
      .order("occasions.date ASC")
    },
    :through => :events,
    :source  => :occasions

  has_and_belongs_to_many :linked_culture_providers, lambda{ order(name: :asc) },
    :class_name              => "CultureProvider",
    :foreign_key             => "from_id",
    :association_foreign_key => "to_id",
    :join_table              => "culture_provider_links"

  has_and_belongs_to_many :linked_events, lambda{ order(name: :asc) }, :class_name => "Event"

  attr_accessible :name,
    :description,
    :contact_person,
    :email,
    :phone,
    :address,
    :opening_hours,
    :url,
    :main_image_id, :main_image,
    :map_address,
    :active

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt."

  default_scope lambda{ order(name: :asc) }

  scope :not_linked_to_culture_provider, lambda{ |culture_provider|
    where("id != ?", culture_provider.id)
    .where("id not in (select to_id from culture_provider_links where from_id = ?)", culture_provider.id)
  }

  scope :not_linked_to_event, lambda { |event|
    where("id != ?", event.culture_provider_id)
    .where("id not in (select culture_provider_id from culture_providers_events where event_id = ?)", event.id)
  }
end
