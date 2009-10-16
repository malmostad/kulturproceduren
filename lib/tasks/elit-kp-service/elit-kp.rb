require 'xsd/qname'

module KP; module Elit


# {http://www.malmo.se/esb/schema/elit-kp}districtType
#   id - SOAP::SOAPString
#   name - SOAP::SOAPString
class DistrictType
  attr_accessor :id
  attr_accessor :name

  def initialize(id = nil, name = nil)
    @id = id
    @name = name
  end
end

# {http://www.malmo.se/esb/schema/elit-kp}schoolType
#   id - SOAP::SOAPString
#   districtId - SOAP::SOAPString
#   name - SOAP::SOAPString
class SchoolType
  attr_accessor :id
  attr_accessor :districtId
  attr_accessor :name

  def initialize(id = nil, districtId = nil, name = nil)
    @id = id
    @districtId = districtId
    @name = name
  end
end

# {http://www.malmo.se/esb/schema/elit-kp}groupType
#   id - SOAP::SOAPString
#   schoolId - SOAP::SOAPString
#   name - SOAP::SOAPString
class GroupType
  attr_accessor :id
  attr_accessor :schoolId
  attr_accessor :name

  def initialize(id = nil, schoolId = nil, name = nil)
    @id = id
    @schoolId = schoolId
    @name = name
  end
end

# {http://www.malmo.se/esb/schema/elit-kp}ageGroupType
#   id - SOAP::SOAPString
#   groupId - SOAP::SOAPString
#   age - SOAP::SOAPInteger
#   amount - SOAP::SOAPInteger
class AgeGroupType
  attr_accessor :id
  attr_accessor :groupId
  attr_accessor :age
  attr_accessor :amount

  def initialize(id = nil, groupId = nil, age = nil, amount = nil)
    @id = id
    @groupId = groupId
    @age = age
    @amount = amount
  end
end

# {http://www.malmo.se/esb/schema/elit-kp}contactType
#   parentId - SOAP::SOAPString
#   email - SOAP::SOAPString
class ContactType
  attr_accessor :parentId
  attr_accessor :email

  def initialize(parentId = nil, email = nil)
    @parentId = parentId
    @email = email
  end
end

# {http://www.malmo.se/esb/schema/elit-kp}collectorType
#   initializer - SOAP::SOAPString
#   schools - KP::Elit::CollectorType::Schools
class CollectorType

  # inner class for member: schools
  # {http://www.malmo.se/esb/schema/elit-kp}schools
  class Schools < ::Array
  end

  attr_accessor :initializer
  attr_accessor :schools

  def initialize(initializer = nil, schools = nil)
    @initializer = initializer
    @schools = schools
  end
end

# {http://www.malmo.se/esb/schema/elit-kp}districtList
class DistrictList < ::Array
end

# {http://www.malmo.se/esb/schema/elit-kp}schoolList
class SchoolList < ::Array
end

# {http://www.malmo.se/esb/schema/elit-kp}groupList
class GroupList < ::Array
end

# {http://www.malmo.se/esb/schema/elit-kp}ageGroupList
class AgeGroupList < ::Array
end

# {http://www.malmo.se/esb/schema/elit-kp}contactList
class ContactList < ::Array
end


end; end
