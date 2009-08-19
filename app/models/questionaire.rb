# A questionnare for a specific event, containing questions for a companion to answer.
class Questionaire < ActiveRecord::Base
  belongs_to                :event
  has_and_belongs_to_many   :questions
  has_many                  :answer_forms

  # Returns an array of the numbers of answers. The first element is the number of answers
  # that are not submitted, and the second is the number of submitted.
  def answered
    return [
      AnswerForm.count(:conditions => {:questionaire_id => self.id , :completed => true}) , 
      AnswerForm.count(:conditions => {:questionaire_id => self.id , :completed => false}) 
    ]
  end
  
end
