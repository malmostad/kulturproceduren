require "kk/ftp_import/base"

class KK::FTP_Import::PreSchoolImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("Wrong row length (#{row.length} fields, expected 5)") if row.length != 5

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
    district_name = attributes[:city_area]
    district_name = 'Fristående' if district_name.nil? or district_name.empty?
    district = District.where(school_type_id: @school_type_id, name: district_name).first
    return nil unless district

    base = School.where(district_id: district.id)

    school = base.where(extens_id: attributes[:extens_id]).first
    school ||= School.new(district_id: district.id)

    school.name = attributes[:name]
    school.extens_id = attributes[:extens_id]
    school.city_area = attributes[:city_area]
    school.district_area = attributes[:district_area]
    school.to_delete = false

    return school
  end
end
