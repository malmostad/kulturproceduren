# A question belonging to one or more questionnaires.
#
# A question can be of different types:
#
# [marks] The answer is a mark between 1 and 4
# [text] The answer is free text
# [bool] The answer is of the form yes/no
# [mchoice] The answer is one of multiple choices. The choices are stored in a CSV field in this model.
#
# A question can be a template question, which means that it is a
# general question available to multiple questionnaires. This way, a
# base template for all questionnaires can be created.
class Question < ActiveRecord::Base

  QTYPES = {
    "Betygssvar" => "QuestionMark",
    "Fritextsvar" => "QuestionText",
    "Ja/Nej svar" => "QuestionBool" ,
    "Flervalsvar" => "QuestionMchoice"
  }
    
  has_and_belongs_to_many :questionnaire 
  has_many :answers, dependent: :destroy

  attr_accessible :qtype,
    :question,
    :choice_csv,
    :template,
    :mandatory

  validates_presence_of :question,
    message: "Frågan får inte vara tom"

  def statistics_for_event(event)
    statistics_for_answer_forms(event.questionnaire.answer_forms)
  end

  # Returns a list with statistics
  # Mark => [ avg_val ]
  # Text => [ answer1 , answer2 .... ]
  # Bool => [ %yes , %no ]
  # Mchoice => { question1 => %answer1 , question2 => %answer2 ... }
  def statistics_for_answer_forms(answer_forms) 
    result = [] 
    no_answers = 0
    sum = 0
    no_yes = 0
    no_no = 0

    if self.qtype == "QuestionMchoice"
      mchoice_stat = {}
      self.choice_csv.split(",").each { |key| mchoice_stat[key] = 0 }
    end

    answer_forms.each do |answer_form| 
      answer_form.answers.each do |answer| 
        if answer.question.id == self.id
          begin
            case self.qtype
            when "QuestionMark"
              sum = sum + answer.answer_text.to_i
            when "QuestionText"
              result.push(answer.answer_text)
            when "QuestionBool"
              if answer.answer_text == "y"
                no_yes = no_yes +1
              else
                no_no = no_no +1
              end
            when "QuestionMchoice"
              mchoice_stat[answer.answer_text] ||= 0
              mchoice_stat[answer.answer_text]  += 1
            end

            no_answers = no_answers + 1
          rescue => e
            Rails.logger.error(e)
          end
        end
      end
    end

    case self.qtype
    when "QuestionMark"
      result.push( no_answers == 0 ? 0.0 : "%2.2f" % (sum.to_f / no_answers.to_f) )
    when "QuestionText"
      #do noting
    when "QuestionBool"
      if no_answers == 0
        result = [ 0.0 , 0.0 ]
      else
        result = ["%.0f" % (( no_yes.to_f / no_answers.to_f).to_f * 100.to_f ) , "%.0f" % ((no_no.to_f / no_answers.to_f).to_f * 100.to_f) ]
      end
    when "QuestionMchoice"
      return mchoice_stat
    end
    return result
  end
end
