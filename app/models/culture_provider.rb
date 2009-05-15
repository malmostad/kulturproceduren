class CultureProvider < ActiveRecord::Base
  has_and_belongs_to_many :User
  has_many :Event
end
