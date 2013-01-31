# String extension
require 'iconv'

class String
  # Converts the string from UTF-8 to ISO-8859-15
  def to_iso
    c = Iconv.new('ISO-8859-15','UTF-8')
    c.iconv(self)
  end
end
