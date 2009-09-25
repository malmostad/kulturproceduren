class AddMapAddressFields < ActiveRecord::Migration
  def self.up
    add_column :culture_providers, :map_address, :string
    add_column :events, :map_address, :string
    add_column :occasions, :map_address, :string
  end

  def self.down
    remove_column :culture_providers, :map_address
    remove_column :events, :map_address
    remove_column :occasions, :map_address
  end
end
