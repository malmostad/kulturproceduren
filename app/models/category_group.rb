# -*- encoding : utf-8 -*-
# A category group is simply a container for grouping mulitple categories together.
#
# Category groups are used in the UI to more clearly present the categories.
class CategoryGroup < ActiveRecord::Base
  has_many :categories, lambda{ order(name: :asc) }, dependent: :destroy
  has_many :events, through: :categories

  attr_accessible :name,
    :visible_in_calendar

  validates_presence_of :name,
    message: "Namnet får inte vara tomt"
end
