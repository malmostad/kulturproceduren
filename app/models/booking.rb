class Booking < ActiveRecord::Base
  belongs_to :group
  belongs_to :occasion
  belongs_to :user
  belongs_to :unbooked_by, :class_name => "User", :foreign_key => "unbooked_by_id"

  has_many :tickets
  has_one :answer_form
end
