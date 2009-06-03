class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  validates_presence_of   :name

  def self.find_by_symbol(sym)
    find :first, :conditions => [ "lower(name) = ?", sym.to_s.downcase ]
  end

  def symbol_name
    name.downcase.to_sym
  end

  def is?(sym)
    name.downcase == sym.to_s.downcase
  end
end
