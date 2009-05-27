class AgeGroup < ActiveRecord::Base
  belongs_to   :group

  validates_numericality_of :age, :quantity, :only_integer => true
end
