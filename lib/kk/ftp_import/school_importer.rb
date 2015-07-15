require "kk/ftp_import/base"

class KK::FTP_Import::SchoolImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("Wrong row length (#{row.length} fields, expected 3)") if row.length != 3

    {
      extens_id: row[0].try(:strip),
      district_id: row[1].try(:strip),
      name: row[2].try(:strip),
      city_area: row[3].try(:strip),
      district_area: row[4].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    district = District.where(school_type_id: @school_type_id, extens_id: attributes[:district_id]).first
    return nil unless district

    base = School.where(district_id: district.id)

    school = base.where(extens_id: attributes[:extens_id]).first
    school ||= School.new(district_id: district.id)

    school.name = attributes[:name]
    school.extens_id = attributes[:extens_id]

    return school
  end
end
