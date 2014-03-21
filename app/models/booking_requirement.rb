# -*- encoding : utf-8 -*-
# A booking requirement is a container for a group's specific
# requirements when booking tickets for an occasion.
class BookingRequirement < ActiveRecord::Base
  belongs_to :group
  belongs_to :occasion

  attr_accessible :requirement,
    :occasion_id, :occasion,
    :group_id,    :group

  # Fetches the booking requirement for a specific group at a specific occasion
  def self.get(group, occasion)
    self.where(group_id: group.id, occasion_id: occasion.id).first
  end
end 
