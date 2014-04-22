# -*- encoding : utf-8 -*-
# An answer form is the collective object for a
# group's answers to a specific questionnaire.
class AnswerForm < ActiveRecord::Base
  # Answer forms have ASCII-ID:s for URL obfuscation
  self.primary_key = "id"
  
  has_many :answers, -> { order("answers.question_id, answers.id") }, :dependent => :destroy
  belongs_to :booking
  belongs_to :occasion
  belongs_to :booking
  belongs_to :questionnaire
  belongs_to :group

  attr_accessible :completed,
    :occasion_id,      :occasion,
    :group_id,         :group,
    :questionnaire_id, :questionnaire,
    :booking_id,       :booking

  before_create :generate_id

  attr_accessor :missing_answers

  # Validates the answer
  def valid_answer?(answer)
    question_ids = []
    answer.keys.each { |k| question_ids << k unless answer[k].blank? }

    unless question_ids.blank?
      missing_answers = self.questionnaire.questions.select { |q| q.mandatory }.collect(&:id) -
        question_ids.map { |k| k.to_i }.sort

      return missing_answers.blank?
    end

    return false
  end

  # Answers the form
  def answer(answer)
    return false if answer.blank?

    if valid_answer?(answer)
      self.completed = true
      self.save!

      answer.each do |question_id, answer_text|
        answer_texts = [answer_text].flatten
        answer_texts.each do |answer_text|
          answers.create! do |a|
            a.question_id = question_id
            a.answer_text = answer_text
          end
        end
      end
      return true
    end

    return false
  end

  # Finds all unanswered forms for occasions the given date
  def self.find_overdue(date)
    self.includes(:occasion, :booking, :group)
      .references(:occasions)
      .where("occasions.date = ?", date)
      .where("occasions.cancelled = ?", false)
      .where("answer_forms.completed = ?", false)
  end

  protected

  # Generates the random ASCII-ID for the answer form
  def generate_id
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    temp = ""
    (1..45).each { |i| temp << chars[rand(chars.size - 1)] }

    self.id = temp
  end
end
