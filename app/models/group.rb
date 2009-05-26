class Group < ActiveRecord::Base
  has_many                  :notification_requests
  has_many                  :tickets

  has_many                  :age_groups do
    def num_children_by_age_span(from, to)
      sum "quantity", :conditions => [ "age between ? and ?", from, to ]
    end
  end

  has_many                  :answers
  has_many                  :booking_requirements
  has_and_belongs_to_many   :users #CultureAdministrator Role
  belongs_to                :school
  
  validates_presence_of     :name
  validates_associated      :school

  attr_accessor :num_children, :num_tickets
end
