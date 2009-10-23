module QuestionsHelper

  # Helper returning a html-fragment containing statistics for a question and event
  # Used in the following way:
  #   <%= render :partial => get_question_statistic_fragment(question,event) ...
  require "pp"
  def get_question_statistic_fragment(question,event)
    stat = question.statistic_for_event(event.id)
    fragment = ""
    case question.qtype
    when "QuestionMark"
      fragment = "Genomsnitt = #{stat[0].to_s}"
    when "QuestionText"
      fragment =  "<ul>"
      stat.each {|e| fragment = fragment + "<li>#{e.to_s}</li>" }
      fragment += "</ul>"
    when "QuestionBool"
      fragment = "Ja #{stat[0]}% , Nej #{stat[1]}%"
    when "QuestionMchoice"
      fragment =  "<table id=\"kp-mchoice-stat\">"
      fragment += "<thead>"
      fragment += "<tr>"
      question.choice_csv.split(",").each { |choice| fragment += "<th>#{choice.to_s}</th>" }
      fragment += "</tr>"
      fragment += "</thead>"
      fragment += "<tbody>"
      fragment += "<tr>"
      stat.each { |result| fragment += "<td>#{result.to_s}</td>"  }
      fragment += "</tr>"
      fragment += "</tbody>"
      fragment += "</table>"
    end
    return fragment
  end
end
