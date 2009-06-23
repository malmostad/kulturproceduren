class Companion < ActiveRecord::Base

  has_one    :answer_form
  has_many   :tickets
  has_one    :group, :through => :tickets
  has_one    :occasion, :through => :tickets
  validates_presence_of :email
  validates_presence_of :name
  validates_presence_of :tel_nr

end

