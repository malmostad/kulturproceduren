require "kp/import/base"

class KP::Import::DistrictImporter < KP::Import::Base
  def initialize(csv, school_type_id, csv_header = false, school_prefix, group_prefix)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KP::Import::ParseError.new("Wrong row length (#{row.length} fields, expected 2)") if row.length != 2

    {
      extens_id: row[0].try(:strip),
      name: row[1].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    base = District.where(school_type_id: @school_type_id)

    district = base.where(extens_id: attributes[:extens_id]).first
    district ||= base.where([ "name ilike ?", attributes[:name] ]).first
    district ||= District.new(school_type_id: @school_type_id)

    district.name = attributes[:name]
    district.extens_id = attributes[:extens_id]

    return district
  end
end
