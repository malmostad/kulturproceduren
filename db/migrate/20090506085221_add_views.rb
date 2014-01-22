# -*- encoding : utf-8 -*-
class AddViews < ActiveRecord::Migration
  def self.up
    execute 'CREATE VIEW quantity_per_district_id AS SELECT districts.id, sum(age_groups.quantity) AS sum FROM districts, schools, groups, age_groups WHERE districts.id = schools.district_id AND schools.id = groups.school_id AND groups.id = age_groups.group_id GROUP BY districts.id'
    execute 'CREATE VIEW quantity_per_group_id AS SELECT groups.id, sum(age_groups.quantity) AS sum FROM schools, groups, age_groups WHERE schools.id = groups.school_id AND groups.id = age_groups.group_id GROUP BY groups.id'
  end

  def self.down
    execute 'DROP VIEW quantity_per_district_id'
    execute 'DROP VIEW quantity_per_group_id'
  end
end
