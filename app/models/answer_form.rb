# An answer form is the collective object for a
# group's answers to a specific questionnaire.
class AnswerForm < ActiveRecord::Base
  # Answer forms have ASCII-ID:s for URL obfuscation
  set_primary_key "id"
  
  has_many :answers, :dependent => :destroy
  belongs_to :occasion
  belongs_to :companion
  belongs_to :booking
  belongs_to :questionnaire
  belongs_to :group

  before_create :generate_id

  attr_accessor :missing_answers

  # Validates the answer
  def valid_answer?(answer)
    question_ids = []
    answer.keys.each { |k| question_ids << k unless answer[k.to_s].blank? }

    unless question_ids.blank?
      @missing_answers = self.questionnaire.questions.select { |q| q.mandatory }.collect(&:id) -
        question_ids.map { |k| k.to_i }.sort

      return @missing_answers.blank?
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
        answers.create(
          :question_id => question_id,
          :answer_text => answer_text
        )
      end
      return true
    end

    return false
  end

  # Finds all unanswered forms for occasions the given date
  def self.find_overdue(date)
    find :all, :conditions => [ "occasions.date = ? and occasions.cancelled = ? and answer_forms.completed = ? and answer_forms.companion_id is not null", date, false, false ],
      :include => [ :occasion, :companion, :group ]
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
