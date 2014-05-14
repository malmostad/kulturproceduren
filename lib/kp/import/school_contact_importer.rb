require "kp/import/base"

class KP::Import::SchoolContactImporter < KP::Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KP::Import::ParseError.new("Wrong row length (#{row.length} fields, expected 3)") if row.length != 3

    contact = row[2].try(:strip)
    return nil if contact.blank?

    {
      contact: row[2].try(:strip),
      school_id: row[0].try(:strip)
    }
  end

  # Contacts do not have unique ids
  def unique_id(attributes)
    nil
  end

  def build(attributes)
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
