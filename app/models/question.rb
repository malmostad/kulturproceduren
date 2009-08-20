# A question belonging to one or more questionnaires.
#
# A question can be of different types:
#
# [marks] The answer is a mark between 1 and 4
# [text] The answer is free text
# [bool] The answer is of the form yes/no
# [mchoice] The answer is one of multiple choices. The choices are stored in a CSV field in this model.
#
# A question can be a template question, which means that it is a
# general question available to multiple questionnaires. This way, a
# base template for all questionnaires can be created.
class Question < ActiveRecord::Base

  QTYPES = {
    "Betygssvar" => "QuestionMark",
    "Fritextsvar" => "QuestionText",
    "Ja/Nej svar" => "QuestionBool" ,
    "Flervalsvar" => "QuestionMchoice"
  }
    
  has_and_belongs_to_many :questionaire 
  has_one :answer

  validates_presence_of :question,
    :message => "Frågan får inte vara tom"
end
