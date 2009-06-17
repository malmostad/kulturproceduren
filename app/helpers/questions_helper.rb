module QuestionsHelper

  def to_html(q , predefs = "" )
    output = String.new
    output += label_tag q.question.to_s
    output += "<br/>"

    case q.qtype 
    when "QuestionMark" then
      output += "<img src=\"/images/yuck.gif\">"
      (1..4).each do |i|
        output += i.to_s + " "
        output += radio_button_tag "answer[#{q.id}]" , i.to_s , i == predefs.to_i
      end
      output += "<img src=\"/images/rockout.gif\">"
    when "QuestionText"
      output += text_field_tag "answer[#{q.id}]" , predefs
    when "QuestionBool"
      output += "Ja" + " "
      output += radio_button_tag "answer[#{q.id}]" , "y" , predefs
      output += "Nej"
      output += radio_button_tag "answer[#{q.id}]" , "n" , (not predefs)
    when "QuestionMchoice"
      q.choice_csv.split(",").each do |o|
        output += o.to_s + " "
        output += check_box_tag "answer[#{q.id}][#{o.to_s}]" , o.to_s , predefs.include?(o.to_s)
      end
    end
    return output
  end

end
