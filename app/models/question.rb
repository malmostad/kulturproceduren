class Question < ActiveRecord::Base

    QTYPES = {"Betygssvar" => "QuestionMark", "Fritextsvar" => "QuestionText", "Ja/Nej svar"=> "QuestionBool" , "Flervalsvar" => "QuestionMchoice"}
  BLABB = 3
  
  has_and_belongs_to_many :questionaire 
  has_one                 :answer

  

end
