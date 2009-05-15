class SchoolPrio < ActiveRecord::Base
  belongs_to   :District
  belongs_to   :School
end
