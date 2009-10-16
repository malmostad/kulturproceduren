require 'soap/mapping'

module KP; module Elit

module ElitKpMappingRegistry
  EncodedRegistry = ::SOAP::Mapping::EncodedRegistry.new
  LiteralRegistry = ::SOAP::Mapping::LiteralRegistry.new
  NsElitKp = "http://www.malmo.se/esb/schema/elit-kp"

  EncodedRegistry.register(
    :class => KP::Elit::DistrictType,
    :schema_type => XSD::QName.new(NsElitKp, "districtType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["name", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => KP::Elit::SchoolType,
    :schema_type => XSD::QName.new(NsElitKp, "schoolType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["districtId", "SOAP::SOAPString"],
      ["name", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => KP::Elit::GroupType,
    :schema_type => XSD::QName.new(NsElitKp, "groupType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["schoolId", "SOAP::SOAPString"],
      ["name", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => KP::Elit::AgeGroupType,
    :schema_type => XSD::QName.new(NsElitKp, "ageGroupType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["groupId", "SOAP::SOAPString"],
      ["age", "SOAP::SOAPInteger"],
      ["amount", "SOAP::SOAPInteger"]
    ]
  )

  EncodedRegistry.register(
    :class => KP::Elit::ContactType,
    :schema_type => XSD::QName.new(NsElitKp, "contactType"),
    :schema_element => [
      ["parentId", "SOAP::SOAPString"],
      ["email", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => KP::Elit::CollectorType,
    :schema_type => XSD::QName.new(NsElitKp, "collectorType"),
    :schema_element => [
      ["initializer", "SOAP::SOAPString"],
      ["schools", "KP::Elit::CollectorType::Schools", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => KP::Elit::CollectorType::Schools,
    :schema_name => XSD::QName.new(NsElitKp, "schools"),
    :is_anonymous => true,
    :schema_qualified => true,
    :schema_element => [
      ["school", "KP::Elit::SchoolType[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::DistrictType,
    :schema_type => XSD::QName.new(NsElitKp, "districtType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["name", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::SchoolType,
    :schema_type => XSD::QName.new(NsElitKp, "schoolType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["districtId", "SOAP::SOAPString"],
      ["name", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::GroupType,
    :schema_type => XSD::QName.new(NsElitKp, "groupType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["schoolId", "SOAP::SOAPString"],
      ["name", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::AgeGroupType,
    :schema_type => XSD::QName.new(NsElitKp, "ageGroupType"),
    :schema_element => [
      ["id", "SOAP::SOAPString"],
      ["groupId", "SOAP::SOAPString"],
      ["age", "SOAP::SOAPInteger"],
      ["amount", "SOAP::SOAPInteger"]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::ContactType,
    :schema_type => XSD::QName.new(NsElitKp, "contactType"),
    :schema_element => [
      ["parentId", "SOAP::SOAPString"],
      ["email", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::CollectorType,
    :schema_type => XSD::QName.new(NsElitKp, "collectorType"),
    :schema_element => [
      ["initializer", "SOAP::SOAPString"],
      ["schools", "KP::Elit::CollectorType::Schools", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::CollectorType::Schools,
    :schema_name => XSD::QName.new(NsElitKp, "schools"),
    :is_anonymous => true,
    :schema_qualified => true,
    :schema_element => [
      ["school", "KP::Elit::SchoolType[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::DistrictList,
    :schema_name => XSD::QName.new(NsElitKp, "districtList"),
    :schema_element => [
      ["district", "KP::Elit::DistrictType[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::SchoolList,
    :schema_name => XSD::QName.new(NsElitKp, "schoolList"),
    :schema_element => [
      ["school", "KP::Elit::SchoolType[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::GroupList,
    :schema_name => XSD::QName.new(NsElitKp, "groupList"),
    :schema_element => [
      ["group", "KP::Elit::GroupType[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::AgeGroupList,
    :schema_name => XSD::QName.new(NsElitKp, "ageGroupList"),
    :schema_element => [
      ["ageGroup", "KP::Elit::AgeGroupType[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => KP::Elit::ContactList,
    :schema_name => XSD::QName.new(NsElitKp, "contactList"),
    :schema_element => [
      ["contact", "KP::Elit::ContactType[]", [0, nil]]
    ]
  )

end

end; end
