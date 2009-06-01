class Companion < ActiveRecord::Base

  has_one    :answer_form
  has_many   :tickets
  has_one    :group, :through => :tickets
  has_one    :occasion, :through => :tickets
  
end

