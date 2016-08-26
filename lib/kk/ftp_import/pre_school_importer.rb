require "kk/ftp_import/base"

class KK::FTP_Import::PreSchoolImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("PreSchoolImporter #{ENV['file']}: Wrong row length (#{row.length} fields, expected 6)") if row.length != 6

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
    district_name = attributes[:district_id]
    district_name = 'Fristående' if district_name.nil? or district_name.empty? or district_name.upcase == 'FRISTÅENDE'

    district = District.where(school_type_id: @school_type_id, name: district_name).first
    unless district
      # enligt överenskommelse med Carolina Wilse på telefon 2016-02-10...
      # ... så skall de förskolor som inte har någon områdeskoppling hamna under 'Fristående'
      district = District.where(school_type_id: @school_type_id, name: 'Fristående').first
    end
    return nil if attributes[:school_type_code].match(/^FSKIK/) #Enligt Anders Ljungdahl är dessa enbart för intrakommunal ersättning
    return nil unless district

    base = School

    school = base.where(extens_id: attributes[:extens_id]).first
    school ||= School.new(district_id: district.id)
    school.district_id = district.id
    school.name = attributes[:name]
    school.extens_id = attributes[:extens_id]
    school.city_area = attributes[:city_area]
    school.district_area = attributes[:district_area]
    school.to_delete = false

    return school
  end
end
