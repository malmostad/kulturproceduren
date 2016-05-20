require "kk/ftp_import/base"

class KK::FTP_Import::PreSchoolDistrictImporterNew < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("PreSchoolDistrictImporterNew #{ENV['file']}: Wrong row length (#{row.length} fields, expected 2)") if row.length != 2
    data = {
      extens_id: row[0].try(:strip),
      name: row[1].try(:strip)
    }
    if !data[:name].nil? && data[:name] == 'NULL' then data[:name] = 'Fristående' end
    return data
  end

  def unique_id(attributes)
    attributes[:name] || 'Fristående'
  end

  def build(attributes)
    base = District.where(school_type_id: @school_type_id)
    district_name = attributes[:name] || 'Fristående'
    extens_id = attributes[:extens_id]

    district = base.where(name: district_name).first
    district ||= District.new(school_type_id: @school_type_id)

    district.name = district_name
    district.extens_id = extens_id
    district.to_delete = false

    return district
  end
end
