# -*- encoding : utf-8 -*-
# An age group is a representation of the number of children of a specific age
# in a specific group.
class AgeGroup < ActiveRecord::Base
  belongs_to :group

  attr_accessible :age,
    :quantity,
    :group_id, :group

  scope :with_district, ->(district_ids) {
    {
      :include => { :group => :school },
      :conditions => { "schools.district_id" => district_ids }
    }
  }
  scope :with_age, ->(from_age, to_age) {
    { :conditions => [ "age between ? and ?", from_age, to_age ] }
  }
  scope :active, :include => :group, :conditions => { "groups.active" => true }
  scope :order_by_group_priority, :include => :group, :order => "groups.priority ASC"

  validates_numericality_of :age,
    :only_integer => true,
    :message => "Åldern måste vara ett giltigt heltal."
  validates_numericality_of :quantity,
    :only_integer => true,
    :message => "Antalet måste vara ett giltigt heltal."


  def self.num_children_per_district
    sum(
      "quantity",
      :include => { :group => :school },
      :group => "schools.district_id",
      :order => "schools.district_id"
    )
  end
  def self.num_children_per_group
    sum(
      "quantity",
      :group => "group_id"
    )
  end
end
