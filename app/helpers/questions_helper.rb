module QuestionsHelper

  # Renders a fragment for displaying questionnaire statistics
  # for a question
  def question_statistics(question, stat)
    return "" if stat.blank?

    fragment = "<table>"

    case question.qtype
    when "QuestionMark"
      fragment += row("Genomsnitt", html_escape(stat[0]))
    when "QuestionText"
      stat.each {|e| fragment += row(html_escape(e)) unless e.blank? }
    when "QuestionBool"
      fragment += row("Ja", html_escape(stat[0]) + "%")
      fragment += row("Nej", html_escape(stat[1]) + "%")
    when "QuestionMchoice"
      stat.keys.sort.each do |choice|
        fragment += row(choice, stat[choice])
      end
    end

    fragment += "</table>"

    return fragment.html_safe
  end

  private

  def row(*content)
    if content.length == 1
      return "<tr><td>#{content[0]}</td></tr>"
    else
      return "<tr><th>#{content[0]}</th><td>#{content[1]}</td></tr>"
    end
  end
end
