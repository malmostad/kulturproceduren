class SchoolPrio < ActiveRecord::Base
  belongs_to   :district
  belongs_to   :school
end
