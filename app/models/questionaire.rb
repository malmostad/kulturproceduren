class Questionaire < ActiveRecord::Base
  
  belongs_to                :event
  has_and_belongs_to_many   :questions
  has_many                  :answer_forms

  def answered
    return [
      AnswerForm.count(:conditions => {:questionaire_id => self.id , :completed => true}) , 
      AnswerForm.count(:conditions => {:questionaire_id => self.id , :completed => false}) 
    ]
  end
  
end
