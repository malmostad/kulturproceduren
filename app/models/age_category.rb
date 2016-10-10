class AgeCategory < ActiveRecord::Base
  attr_accessible :name, :from_age, :to_age, :further_education, :sort_order
end
