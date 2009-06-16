class Questionaire < ActiveRecord::Base
  require "pp"
  belongs_to                :event
  has_and_belongs_to_many   :questions


  has_many                  :answer_forms

#  def question_ids
#    Question.allq.select { |a| a.questionaire_ids.include?(self.id) }.map { |a| a.id }
#  end
#  def questions
#    Question.allq.select { |a| a.questionaire_ids.include?(self.id) }
#  end
#
#  def questions=(qarr)
#
#    qarr.each do |q|
#      q.questionaire << self unless q.questionaire.include?(self);
#      q.save
#    end
#  end
#
#  def question_ids=(qids)
#    qarr = []
#    qids.each { |q| qarr << Question.find(q) }
#    self.questions=qarr
#  end
#
end
