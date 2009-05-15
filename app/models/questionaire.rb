class Questionaire < ActiveRecord::Base
  belongs_to  :Event
  has_many    :Question
end
