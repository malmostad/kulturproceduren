# A questionnare for a specific event, containing questions for a companion to answer.
class Questionnaire < ActiveRecord::Base
  belongs_to                :event
  has_and_belongs_to_many   :questions, :order => "questions.question ASC"
  has_many                  :answer_forms, :dependent => :destroy

  # Returns an array of the numbers of answers. The first element is the number of answers
  # that are not submitted, and the second is the number of submitted.
  def answered
    return [
      AnswerForm.count(:conditions => {:questionnaire_id => self.id , :completed => true}) , 
      AnswerForm.count(:conditions => {:questionnaire_id => self.id , :completed => false}) 
    ]
  end
  
end
