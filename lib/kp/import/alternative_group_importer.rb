require "kp/import/group_importer"

# This class imports groups from a file that contains
# age groups. The importer is used for importing preschool
# groups which currently do not have their own export file from
# Extens
class KP::Import::AlternativeGroupImporter < KP::Import::GroupImporter
  def attributes_from_row(row)
    raise KP::Import::ParseError.new("Wrong row length (#{row.length} fields, expected 6)") if row.length != 6

    {
      school_id: row[0].try(:strip),
      extens_id: row[1].try(:strip),
      name: row[2].try(:strip)
    }
  end
end
