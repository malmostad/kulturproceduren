require "kp/import/base"

class KP::Import::GroupImporter < KP::Import::Base
  def initialize(csv, school_type_id, csv_header = false, school_prefix, group_prefix)
    super(csv, csv_header)
    @school_type_id = school_type_id
    
    # Handle prefixes added to extens_id in db
    @school_prefix = school_prefix
    @group_prefix = group_prefix
  end

  def attributes_from_row(row)
    raise KP::Import::ParseError.new("Wrong row length (#{row.length} fields, expected 3)") if row.length != 3

    {
      extens_id: row[0].try(:strip),
      school_id: row[1].try(:strip),
      name: row[2].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    school = School.includes(:district).references(:district)
      .where([ "districts.school_type_id = ?", @school_type_id ])
      .where(extens_id: @school_prefix+attributes[:school_id]).first
    return nil unless school

    base = Group.where(school_id: school.id)

    group = base.where(extens_id: @group_prefix+attributes[:extens_id]).first
    group ||= Group.new(school_id: school.id)

    group.name = attributes[:name]
    group.extens_id = @group_prefix+attributes[:extens_id]
    group.active = true

    return group
  end
end
