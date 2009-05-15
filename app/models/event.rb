class Event < ActiveRecord::Base
  has_many   :Ticket
  has_many   :Occasion
  validates_presence_of :from_age, :to_age, :description
  has_and_belongs_to_many :Tag
  belongs_to :CultureProvider
  has_one :Questionaire
end
