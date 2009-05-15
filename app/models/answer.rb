class Answer < ActiveRecord::Base
  belongs_to :Question
  belongs_to :Occasion
  belongs_to :Group
end
