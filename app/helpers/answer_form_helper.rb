# -*- encoding : utf-8 -*-
module AnswerFormHelper

  # Helper returning the name of the Rails fragment to render
  # when a question is of a specific type.
  #
  # Used in the following way:
  #   <%= render partial: get_question_fragment(question) ...
  def get_question_fragment(question)
    case question.qtype 
    when "QuestionMark" then
      "answer_form/mark"
    when "QuestionText"
      "answer_form/text"
    when "QuestionBool"
      "answer_form/bool"
    when "QuestionMchoice"
      "answer_form/mchoice"
    end
  end

end
