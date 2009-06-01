class Questionaire < ActiveRecord::Base

  belongs_to                :event
  has_and_belongs_to_many   :questions
  has_many                  :answer_forms

end
