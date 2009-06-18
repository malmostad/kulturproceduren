class Category < ActiveRecord::Base
  belongs_to :category_group
  has_and_belongs_to_many :events

  validates_presence_of :name
end
