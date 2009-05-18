class Event < ActiveRecord::Base
  has_many                :tickets
  has_many                :occasions
  has_and_belongs_to_many :tags
  belongs_to              :culture_provider
  has_one                 :questionaire

  validates_presence_of :from_age, :to_age, :description

end
