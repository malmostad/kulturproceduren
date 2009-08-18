# An answer is the answer to a question in a questionnaire.
class Answer < ActiveRecord::Base
  belongs_to :question
  belongs_to :answer_form
end
