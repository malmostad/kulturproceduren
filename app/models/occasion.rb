class Occasion < ActiveRecord::Base
  belongs_to              :event
  has_many                :tickets
  has_many                :booking_requirements
  has_many                :notification_request
  has_many                :groups, :through => :tickets
  has_many                :users #Host role
  belongs_to              :answer

  validates_presence_of   :date, :seats, :address
  validates_numericality_of :seats, :only_integer => true

end

