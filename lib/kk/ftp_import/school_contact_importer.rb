require "kk/ftp_import/base"

class KK::FTP_Import::SchoolContactImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("Wrong row length (#{row.length} fields, expected 2)") if row.length != 2

    contact = row[1].try(:strip)
    return nil if contact.blank?

    {
      school_id: row[0].try(:strip),
      contact: contact
    }
  end

  # Contacts do not have unique ids
  def unique_id(attributes)
    nil
  end

  def build(attributes)
    #puts "#{@school_prefix+attributes[:school_id]}"

    school = School.includes(:district).references(:district)
      .where([ "districts.school_type_id = ?", @school_type_id ])
      .where(extens_id: attributes[:school_id]).first
    return nil unless school

    contacts = school.contacts.try(:split, ",") || []
    contacts << attributes[:contact]
    school.contacts = contacts.uniq.sort.join(",")

    return school
  end
end
