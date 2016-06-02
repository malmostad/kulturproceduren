class Allotment < ActiveRecord::Base
  belongs_to :user
  belongs_to :event
  belongs_to :district
  belongs_to :group
  belongs_to :school
  has_many :tickets, dependent: :delete_all

  attr_accessible :amount,
    :user_id,     :user,
    :event_id,    :event,
    :district_id, :district,
    :group_id,    :group,
    :school_id,   :school,
    :excluded_district_ids

  after_save :synchronize_tickets

  validates_presence_of :user, message: "Tilldelningen måste tillhöra en grupp"
  validates_presence_of :event, message: "Tilldelningen måste tillhöra ett evenemang"

  def allotment_type
    if self.group_id
      :group
    elsif self.school_id
      :school
    elsif self.district_id
      :district
    elsif !self.excluded_district_ids.empty?
      :free_for_all_with_excluded_districts
    else
      :free_for_all
    end
  end

  def for_group?
    !self.group_id.nil?
  end

  def for_school?
    !self.school_id.nil?
  end

  def for_district?
    self.group_id.nil? && self.school_id.nil? && !self.district_id.nil?
  end

  def for_all_with_excluded_districts?
    self.group_id.nil? && self.school_id.nil? && self.district_id.nil? && !self.excluded_district_ids.empty?
  end

  def for_all?
    self.group_id.nil? && self.school_id.nil? && self.district_id.nil? && self.excluded_district_ids.empty?
  end


  private

  def synchronize_tickets
    1.upto(self.amount) do
      self.tickets.create!(
        event: self.event,
        district: self.district,
        group: self.group,
        state: :unbooked,
        wheelchair: false,
        adult: false
      )
    end
  end

end
