# A container for the role definitions iun the system.
#
# The roles in the system are the following:
#
# [+:admin+] Administrators, full privileges
# [+:booker+] Booking privileges, the user can book tickets for groups
# [+:culture_worker+] Culture worker privileges, the user can administrate the profiles for specific culture providers
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  validates_presence_of   :name

  # Finds a specific role using a symbol, for constantized referencing of
  # roles in the code
  def self.find_by_symbol(sym)
    find :first, :conditions => [ "lower(name) = ?", sym.to_s.downcase ]
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
