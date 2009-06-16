class Question < ActiveRecord::Base

  self.abstract_class = true
  
  has_and_belongs_to_many :questionaire , :join_table => :questionaires_questions , :foreign_key => :question_id
  has_one                 :answer

  def self.allq
    puts "In question-model"
    retval = []
    a = []
    Question.send( :subclasses ).each do |c|
      puts "Subclass = #{c.class}"
      if c.send( :subclasses).length == 0
        a = c.all
        retval += a unless a.blank?
      end
    end
    pp retval
    return retval
  end


end
