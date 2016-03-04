require "kk/ftp_import/base"

class KK::FTP_Import::PreSchoolDistrictImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("PreSchoolDistrictImporter #{ENV['file']}: Wrong row length (#{row.length} fields, expected 5)") if row.length != 5

    {
      name: row[3].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:name] || 'Fristående'
  end

  def build(attributes)
    base = District.where(school_type_id: @school_type_id)
    district_name = attributes[:name] || 'Fristående'

    district = base.where(name: district_name).first
    district ||= District.new(school_type_id: @school_type_id)

    district.name = district_name
    district.extens_id = "Pre-School-District-" + district_name
    district.to_delete = false

    return district
  end
end
