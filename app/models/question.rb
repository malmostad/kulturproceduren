class Question < ActiveRecord::Base

  self.abstract_class = true

  has_and_belongs_to_many :questionaire
  has_one                 :answer

  def self.allq
    retval = []
    Question.send( :subclasses ).each do |c|
      if c.send( :subclasses).length == 0
        retval << c.all
      end
    end
    return retval
  end

end
