module AnswerFormHelper

  # Helper returning the name of the Rails fragment to render
  # when a question is of a specific type.
  #
  # Used in the following way:
  #   <%= render :partial => get_question_fragment(question) ...
  def get_question_fragment(question)
    case question.qtype 
    when "QuestionMark" then
      return "mark"
    when "QuestionText"
      return "text"
    when "QuestionBool"
      return "bool"
    when "QuestionMchoice"
      return "mchoice"
    end
  end

end
