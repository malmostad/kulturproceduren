require "kp/import/base"

class KP::Import::AgeGroupImporter < KP::Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id

    # Calculate the age based on the current school year
    @base_year = (Date.today - 6.months).year

    # Track updated age groups, per group
    @updated = {}
  end

  def attributes_from_row(row)
    raise KP::Import::ParseError.new("Wrong row length (#{row.length} fields, expected 6)") if row.length != 6

    {
      birth_year: row[5].try(:to_i),
      quantity: row[4].try(:to_i),
      group_id: row[1].try(:strip)
    }
  end

  # Age groups do not have unique ids
  def unique_id(attributes)
    nil
  end

  def build(attributes)
    group = Group.includes(school: :district).references(:district, :school)
      .where([ "districts.school_type_id = ?", @school_type_id ])
      .where(extens_id: attributes[:group_id]).first

    return nil unless group

    age = @base_year - attributes[:birth_year] if attributes[:birth_year]

    age_group = group.age_groups.detect { |ag| ag.age == age }
    age_group ||= group.age_groups.build(age: age)

    age_group.quantity = attributes[:quantity]

    # Track existing age groups which will be updated
    @updated[group.id] ||= []
    @updated[group.id] << age_group.id unless age_group.new_record?

    return age_group
  end


  # Delete all age groups which have not been updated, only for groups
  # that actually have had their age groups updated
  def before_import(result)
    result[:deleted] = 0

    @updated.each do |group_id, age_group_ids|
      unless age_group_ids.blank?
        result[:deleted] += AgeGroup.where(group_id: group_id)
          .where([ "id not in (?)", age_group_ids ])
          .delete_all
      end
    end
  end
end
