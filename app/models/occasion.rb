class Occasion < ActiveRecord::Base



  belongs_to              :event
  has_many                :tickets
  has_many                :booking_requirements
  has_many                :notification_request
  has_many                :groups, :through => :tickets , :uniq => true
  has_many                :users #Host role
  belongs_to              :answer

  validates_presence_of   :date, :seats, :address
  validates_numericality_of :seats, :only_integer => true


  def self.visible_by_date
    today = Date.today
    ocs = Occasion.find(:all)
    res = Array.new
    ocs.each do |o|
      if o.event.show_date < today
        res.push(o)
      end
    end
    return res
  end

end

