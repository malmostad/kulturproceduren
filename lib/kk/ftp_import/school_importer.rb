require "kk/ftp_import/base"

class KK::FTP_Import::SchoolImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("Wrong row length (#{row.length} fields, expected 6)") if row.length != 6

    {
      extens_id: row[0].try(:strip),
      district_id: row[1].try(:strip),
      name: row[2].try(:strip),
      city_area: row[3].try(:strip),
      district_area: row[4].try(:strip),
      school_type_code: row[5].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    district = District.where(school_type_id: @school_type_id, extens_id: attributes[:district_id]).first
    unless district
      # enligt överenskommelse med Carolina Wilse på telefon 2016-02-10...
      # ... så skall de skolor som inte har någon områdeskoppling hamna under 'Gymnasieförvaltningen'
      district = District.where(school_type_id: @school_type_id, name: 'Gymnasieförvaltningen').first
    end
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
