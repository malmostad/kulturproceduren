require "kk/ftp_import/base"

class KK::FTP_Import::SchoolImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("SchoolImporter #{ENV['file']}: Wrong row length (#{row.length} fields, expected 5)") if row.length != 5

    {
      extens_id: row[0].try(:strip),
      district_id: row[1].try(:strip),
      name: row[2].try(:strip),
      district_area: row[3].try(:strip),
      school_type_code: row[4].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    school_id = attributes[:extens_id]

    district = District.where(school_type_id: @school_type_id, extens_id: attributes[:district_id]).first
    unless district
      # enligt överenskommelse med Carolina Wilse på telefon 2016-02-10...
      # ... så skall de skolor som inte har någon områdeskoppling hamna under 'Gymnasieförvaltningen'
      district = District.where(school_type_id: @school_type_id, name: 'Gymnasieförvaltningen').first
    end
    return nil if !attributes[:school_type_code].match(/^AKGR/).nil? #Enligt Anders Ljungdahl behöver inte dessa vara med
    return nil unless district

    base = School

    school = base.where(extens_id: attributes[:extens_id]).first
    school ||= School.new(district_id: district.id)
    school.district_id = district.id
    school.name = attributes[:name]
    school.extens_id = attributes[:extens_id]
    #school.city_area = attributes[:city_area]
    school.district_area = attributes[:district_area]
    school.to_delete = false

    return school
  end
end
