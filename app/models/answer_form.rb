# An answer form is the collective object for a
# group's answers to a specific questionnaire.
class AnswerForm < ActiveRecord::Base
  # Answer forms have ASCII-ID:s for URL obfuscation
  set_primary_key "id"
  
  has_many :answers
  belongs_to :occasion
  belongs_to :companion
  belongs_to :questionaire
  belongs_to :group
end
