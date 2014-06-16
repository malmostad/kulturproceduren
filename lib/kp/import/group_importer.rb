require "kp/import/base"

class KP::Import::GroupImporter < KP::Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KP::Import::ParseError.new("Wrong row length (#{row.length} fields, expected 4)") if row.length != 4

    {
      name: row[3].try(:strip),
      extens_id: row[0].try(:strip),
      school_id: row[1].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    school = School.includes(:district).references(:district)
      .where([ "districts.school_type_id = ?", @school_type_id ])
      .where(extens_id: attributes[:school_id]).first
    return nil unless school

    base = Group.where(school_id: school.id)

    group = base.where(extens_id: attributes[:extens_id]).first
    group ||= Group.new(school_id: school.id)

    group.name = attributes[:name]
    group.extens_id = attributes[:extens_id]
    group.active = true

    return group
  end
end
