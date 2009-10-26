class AddActiveFlagToCultureProviders < ActiveRecord::Migration
  def self.up
    add_column :culture_providers, :active, :boolean, :default => true

    CultureProvider.update_all [ "active = ?", true ]
  end

  def self.down
    remove_column :culture_providers, :active
  end
end
