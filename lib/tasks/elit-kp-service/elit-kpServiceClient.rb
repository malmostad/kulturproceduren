#!/usr/bin/env ruby
require 'elit-kpDriver.rb'


module KP::Elit

endpoint_url = ARGV.shift
obj = ElitKpPortType.new(endpoint_url)

# run ruby with -d to see SOAP wiredumps.
obj.wiredump_dev = STDERR if $DEBUG

# SYNOPSIS
#   getDistricts(input)
#
# ARGS
#   input           C_String - {http://www.w3.org/2001/XMLSchema}string
#
# RETURNS
#   districts       DistrictList - {http://www.malmo.se/esb/schema/elit-kp}districtList
#
input = nil
puts obj.getDistricts(input)

# SYNOPSIS
#   getSchools(input)
#
# ARGS
#   input           C_String - {http://www.w3.org/2001/XMLSchema}string
#
# RETURNS
#   schools         SchoolList - {http://www.malmo.se/esb/schema/elit-kp}schoolList
#
input = nil
puts obj.getSchools(input)

# SYNOPSIS
#   getGroups(input)
#
# ARGS
#   input           C_String - {http://www.w3.org/2001/XMLSchema}string
#
# RETURNS
#   groups          GroupList - {http://www.malmo.se/esb/schema/elit-kp}groupList
#
input = nil
puts obj.getGroups(input)

# SYNOPSIS
#   getAgeGroups(input)
#
# ARGS
#   input           C_String - {http://www.w3.org/2001/XMLSchema}string
#
# RETURNS
#   ageGroups       AgeGroupList - {http://www.malmo.se/esb/schema/elit-kp}ageGroupList
#
input = nil
puts obj.getAgeGroups(input)

# SYNOPSIS
#   getSchoolContacts(input)
#
# ARGS
#   input           C_String - {http://www.w3.org/2001/XMLSchema}string
#
# RETURNS
#   schoolContacts  ContactList - {http://www.malmo.se/esb/schema/elit-kp}contactList
#
input = nil
puts obj.getSchoolContacts(input)

# SYNOPSIS
#   getGroupContacts(input)
#
# ARGS
#   input           C_String - {http://www.w3.org/2001/XMLSchema}string
#
# RETURNS
#   groupContacts   ContactList - {http://www.malmo.se/esb/schema/elit-kp}contactList
#
input = nil
puts obj.getGroupContacts(input)




end
