class Question < ActiveRecord::Base
  belongs_to   :Questionaire
  has_one      :Answer
end
