class Role < ActiveRecord::Base
  has_and_belongs_to_many   :User
  validate_presence_of  :name
end
