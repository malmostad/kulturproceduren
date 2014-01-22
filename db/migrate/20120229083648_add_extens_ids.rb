# -*- encoding : utf-8 -*-
class AddExtensIds < ActiveRecord::Migration
  def self.up
    add_column :districts, :extens_id, :string, :limit => 64
    add_column :schools, :extens_id, :string, :limit => 64
    add_column :groups, :extens_id, :string, :limit => 64
    add_index :districts, :extens_id
    add_index :schools, :extens_id
    add_index :groups, :extens_id
  end

  def self.down
    remove_index :districts, :extens_id
    remove_index :schools, :extens_id
    remove_index :groups, :extens_id
    remove_column :districts, :extens_id
    remove_column :schools, :extens_id
    remove_column :groups, :extens_id
  end
end
