module QuestionsHelper

  # Renders a fragment for displaying questionnaire statistics
  # for a question
  def question_statistics(question, stat)
    fragment = ""

    case question.qtype
    when "QuestionMark"
      fragment = "Genomsnitt = #{html_escape(stat[0])}"
    when "QuestionText"
      fragment =  "<ul>"
      stat.each {|e| fragment = fragment + "<li>#{html_escape(e)}</li>" unless e.blank? }
      fragment += "</ul>"
    when "QuestionBool"
      fragment = "Ja #{html_escape(stat[0])}% , Nej #{html_escape(stat[1])}%"
    when "QuestionMchoice"
      choices = stat.keys.sort
      fragment =  "<table id=\"kp-mchoice-stat\">"
      fragment += "<thead>"
      fragment += "<tr>"
      choices.each { |choice| fragment += "<th>#{html_escape(choice)}</th>" }
      fragment += "</tr>"
      fragment += "</thead>"
      fragment += "<tbody>"
      fragment += "<tr>"
      choices.each { |choice| fragment += "<td>#{html_escape(stat[choice])}</td>" }
      fragment += "</tr>"
      fragment += "</tbody>"
      fragment += "</table>"
    end
    return fragment.html_safe
  end
end
