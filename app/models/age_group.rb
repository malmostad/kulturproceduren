# An age group is a representation of the number of children of a specific age
# in a specific group.
class AgeGroup < ActiveRecord::Base
  belongs_to :group

  attr_accessible :age,
    :quantity,
    :group_id, :group

  scope :with_district, lambda{ |district_ids|
    where("schools.district_id" => district_ids).includes(group: :school)
  }

  scope :with_age, lambda{ |from_age, to_age|
    where("age BETWEEN ? AND ?", from_age, to_age)
  }

  scope :active, lambda{ where("groups.active").includes(:group).references(:groups) }

  scope :order_by_group_priority, lambda{ includes(:group).order("groups.priority ASC") }


  validates_numericality_of :age,
    only_integer: true,
    message: "Åldern måste vara ett giltigt heltal."
  validates_numericality_of :quantity,
    only_integer: true,
    message: "Antalet måste vara ett giltigt heltal."


  def self.num_children_per_district
    {}.tap do |result|
      counts = self.includes(group: :school).order("schools.district_id").group("schools.district_id").sum(:quantity)
      counts.each{ |k, v| result[k.to_s] = v }
    end
  end


  def self.num_children_per_group
    self.group(:group_id).sum(:quantity)
  end
end
