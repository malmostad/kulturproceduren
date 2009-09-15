# An answer form is the collective object for a
# group's answers to a specific questionnaire.
class AnswerForm < ActiveRecord::Base
  # Answer forms have ASCII-ID:s for URL obfuscation
  set_primary_key "id"
  
  has_many :answers, :dependent => :destroy
  belongs_to :occasion
  belongs_to :companion
  belongs_to :questionaire
  belongs_to :group

  before_create :generate_id

  # Finds all unanswered forms that are older than the given date
  def self.find_overdue(date)
    find :all, :conditions => [ "occasions.date < ? and answer_forms.completed = ?", date, false ],
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
