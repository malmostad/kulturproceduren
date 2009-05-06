class CultureAdministrator < ActiveRecord::Base
  has_and_belongs_to_many   :Group
  validates_presence_of     :name, :mobil_nr, :email
end
