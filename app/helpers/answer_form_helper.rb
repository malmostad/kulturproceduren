module AnswerFormHelper

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
