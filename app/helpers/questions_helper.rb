module QuestionsHelper

  require "pp"
  require 'rubygems'
  require 'gruff'

  def question_to_html(q , predefs = "" )
    output = String.new
    output += label_tag q.question.to_s
    output += "<br/>"

    case q.qtype 
    when "QuestionMark" then
      output += "<img src=\"/images/doh2.gif\">"

      (1..4).each do |i|
        output += radio_button_tag "answer[#{q.id}]" , i.to_s , i == predefs.to_i
        output += i.to_s + " "
      end
      
      output += "<img src=\"/images/woot.gif\">"
    when "QuestionText"
      output += text_field_tag "answer[#{q.id}]" , predefs
    when "QuestionBool"
      output += radio_button_tag "answer[#{q.id}]" , "y" , predefs
      output += "Ja" + " "
      output += radio_button_tag "answer[#{q.id}]" , "n" , (not predefs)
      output += "Nej"
    when "QuestionMchoice"
      q.choice_csv.split(",").each do |o|
        output += check_box_tag "answer[#{q.id}][#{o.to_s}]" , o.to_s , predefs.include?(o.to_s)
        output += o.to_s + " "
      end
    end
    
    return output
  end


end
