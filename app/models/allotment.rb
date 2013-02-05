class Allotment < ActiveRecord::Base
  belongs_to :user
  belongs_to :event
  belongs_to :district
  belongs_to :group
  has_many :tickets, :dependent => :delete_all

  after_save :synchronize_tickets

  validates_presence_of :user, :message => "Tilldelningen måste tillhöra en grupp"
  validates_presence_of :event, :message => "Tilldelningen måste tillhöra ett evenemang"

  def allotment_type
    if self.group_id
      :group
    elsif self.district_id
      :district
    else
      :free_for_all
    end
  end


  private

  def synchronize_tickets
    1.upto(self.amount) do
      self.tickets.create!(
        :event => self.event,
        :district => self.district,
        :group => self.group,
        :state => Ticket::UNBOOKED
      )
    end
  end

end
