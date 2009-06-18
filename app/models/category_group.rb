class CategoryGroup < ActiveRecord::Base
  has_many :categories, :dependent => :destroy
  has_many :events, :through => :categories

  validates_presence_of :name
end
