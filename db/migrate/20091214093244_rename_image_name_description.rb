class RenameImageNameDescription < ActiveRecord::Migration
  def self.up
    rename_column :images, :name, :description
  end

  def self.down
    rename_column :images, :description, :name
  end
end
