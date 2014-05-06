class SchoolType < ActiveRecord::Base
  has_many :districts, dependent: :destroy

  attr_accessible :name

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt."

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  default_scope { active }
end
