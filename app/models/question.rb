class Question < ActiveRecord::Base
  belongs_to :questionaire
  has_one    :answer
end
