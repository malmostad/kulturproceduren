# -*- encoding : utf-8 -*-
# A container for the role definitions iun the system.
#
# The roles in the system are the following:
#
# [<tt>:admin</tt>] Administrators, full privileges
# [<tt>:booker</tt>] Booking privileges, the user can book tickets for groups
# [<tt>:culture_worker</tt>] Culture worker privileges, the user can administrate the profiles for specific culture providers
# [<tt>:host</tt>] Host privileges, the user can handle the attendance lists on occasions
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  attr_accessible :name

  validates_presence_of   :name

  # Finds a specific role using a symbol, for constantized referencing of
  # roles in the code
  def self.find_by_symbol(sym)
    self.where("lower(name) = ?", sym.to_s.downcase).first
  end

  # Returns the role's name as a symbol
  def symbol_name
    name.downcase.to_sym
  end

  # Returns true if this role is the same as the given symbol
  def is?(sym)
    name.downcase == sym.to_s.downcase
  end
end
