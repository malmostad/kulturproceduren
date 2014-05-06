# -*- encoding : utf-8 -*-
class AddInactiveFlagToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :active, :boolean, default: true
    Group.update_all [ "active = ?", true ]
  end

  def self.down
    remove_column :groups, :active
  end
end
