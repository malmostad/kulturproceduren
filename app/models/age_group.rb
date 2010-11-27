# An age group is a representation of the number of children of a specific age
# in a specific group.
class AgeGroup < ActiveRecord::Base
  belongs_to :group

  named_scope :with_district, lambda { |district_ids|
    {
      :include => { :group => :school },
      :conditions => { "schools.district_id", district_ids }
    }
  }
  named_scope :with_age, lambda { |from_age, to_age|
    { :conditions => [ "age between ? and ?", from_age, to_age ] }
  }
  named_scope :active, :include => :group, :conditions => { "groups.active" => true }
  named_scope :order_by_group_priority, :include => :group, :order => "groups.priority ASC"

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
      :group => "schools.district_id"
    )
  end
  def self.num_children_per_group
    sum(
      "quantity",
      :group => "group_id"
    )
  end
end
