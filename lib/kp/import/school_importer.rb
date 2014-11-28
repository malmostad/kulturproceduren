require "kp/import/base"

class KP::Import::SchoolImporter < KP::Import::Base
  def initialize(csv, school_type_id, csv_header = false, school_prefix, group_prefix)
    super(csv, csv_header)
    @school_type_id = school_type_id

    # Handle prefixes added to extens_id in db
    @school_prefix = school_prefix
    @group_prefix = group_prefix
  end

  def attributes_from_row(row)
    raise KP::Import::ParseError.new("Wrong row length (#{row.length} fields, expected 3)") if row.length != 3

    {
      extens_id: row[0].try(:strip),
      district_id: row[1].try(:strip),
      name: row[2].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    district = District.where(school_type_id: @school_type_id, extens_id: attributes[:district_id]).first
    return nil unless district

    base = School.where(district_id: district.id)

    school = base.where(extens_id: @school_prefix+attributes[:extens_id]).first
    school ||= base.where([ "name ilike ?", attributes[:name] ]).first
    school ||= School.new(district_id: district.id)

    school.name = attributes[:name]
    school.extens_id = @school_prefix+attributes[:extens_id]

    return school
  end
end
