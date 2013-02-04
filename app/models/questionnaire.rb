# A questionnare for a specific event, containing questions for a companion to answer.
class Questionnaire < ActiveRecord::Base
  belongs_to                :event
  has_and_belongs_to_many   :questions, :order => "questions.question ASC"
  has_many                  :answer_forms, :dependent => :destroy

  as_enum :target, { :for_event => 1, :for_unbooking => 2 }, :slim => :class

  named_scope :for_event, :conditions => { :target_cd => targets.for_event }
  named_scope :for_unbooking, :conditions => { :target_cd => targets.for_unbooking }

  # Returns an array of the numbers of answers. The first element is the number of answers
  # that are not submitted, and the second is the number of submitted.
  def answered
    return [
      AnswerForm.count(:conditions => {:questionnaire_id => self.id , :completed => true}) , 
      AnswerForm.count(:conditions => {:questionnaire_id => self.id , :completed => false}) 
    ]
  end
  

  # Finds the single unbooking questionnaire
  def self.find_unbooking
    questionnaire = for_unbooking.first
    questionnaire ||= Questionnaire.create(
      :description => "Avbokningsenkät",
      :target_cd => targets.for_unbooking
    )
    
    return questionnaire
  end
end
