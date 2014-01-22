# -*- encoding : utf-8 -*-
class ConvertElitIdsToStrings < ActiveRecord::Migration
  def self.up
    change_column :districts, :elit_id, :string
    change_column :schools, :elit_id, :string
    change_column :groups, :elit_id, :string
  end

  def self.down
    District.update_all "elit_id = nil"
    School.update_all "elit_id = nil"
    Group.update_all "elit_id = nil"

    change_column :districts, :elit_id, :integer
    change_column :schools, :elit_id, :integer
    change_column :groups, :elit_id, :integer
  end
end
