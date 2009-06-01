class AnswerForm < ActiveRecord::Base

  set_primary_key "id"
  
  has_many    :answers
  belongs_to  :occasion
  belongs_to  :companion
  belongs_to  :questionaire
  belongs_to  :group

end
