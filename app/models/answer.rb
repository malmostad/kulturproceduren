class Answer < ActiveRecord::Base
  belongs_to :question
  belongs_to :occasion
  belongs_to :group
end
