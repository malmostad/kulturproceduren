class School < ActiveRecord::Base
  has_many   :Group
  belongs_to :District
  validates_presence_of  :name, :district_id
  validates_associated   :District, :Group

end
