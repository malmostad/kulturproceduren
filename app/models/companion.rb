# A companion is personal details of a person accompanying children
# to booked occasions.
class Companion < ActiveRecord::Base
  has_one :answer_form
  has_many :tickets
  has_one :group, :through => :tickets
  has_one :occasion, :through => :tickets

  validates_presence_of :email,
    :message => "Epostadressen får inte vara tom."
  validates_presence_of :name,
    :message => "Namnet får inte vara tomt."
  validates_presence_of :tel_nr,
    :message => "Telefonnumret får inte vara tomt."

  # Fetches the companion for a specific group at a specific occasion
  def self.get(group, occasion)
    Ticket.find(:first, :conditions => {
      :group_id => group.id,
      :occasion_id => occasion.id,
      :state => Ticket::BOOKED
    }).companion
  end
end

