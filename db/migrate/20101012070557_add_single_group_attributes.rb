class AddSingleGroupAttributes < ActiveRecord::Migration
  def self.up
    add_column :events, :single_group_per_occasion, :boolean, :default => false
    add_column :occasions, :single_group, :boolean, :default => false

    Event.update_all [ "single_group_per_occasion = ?", false ]
    Occasion.update_all [ "single_group = ?", false ]
  end

  def self.down
    remove_column :occasions, :single_group
    remove_column :events, :single_group_per_occasion
  end
end
