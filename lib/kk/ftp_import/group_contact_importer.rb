require "kk/ftp_import/base"

class KK::FTP_Import::GroupContactImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("Wrong row length (#{row.length} fields, expected 2)") if row.length != 2

    contact = row[1].try(:strip)
    return nil if contact.blank?

    {
      group_id: row[0].try(:strip),
      contact: contact
    }
  end

  # Contacts do not have unique ids
  def unique_id(attributes)
    nil
  end

  def build(attributes)
    group = Group.includes(school: :district).references(:district, :school)
      .where([ "districts.school_type_id = ?", @school_type_id ])
      .where(extens_id: attributes[:group_id]).first
    return nil unless group

    contacts = group.contacts.try(:split, ",") || []
    if !attributes[:contact].nil? && !attributes[:contact].match(/@/).nil?
      contacts << attributes[:contact]
    end
    group.contacts = contacts.uniq.sort.join(",")

    return group
  end
end
