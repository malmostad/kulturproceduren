# -*- encoding : utf-8 -*-
# An answer is the answer to a question in a questionnaire.
class Answer < ActiveRecord::Base
  belongs_to :question
  belongs_to :answer_form

  attr_accessible :answer_text,
    :question_id,    :question,
    :answer_form_id, :answer_form
end
