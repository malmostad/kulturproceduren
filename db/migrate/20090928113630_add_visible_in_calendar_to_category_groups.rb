class AddVisibleInCalendarToCategoryGroups < ActiveRecord::Migration
  def self.up
    add_column :category_groups, :visible_in_calendar, :boolean,
      :default => true
  end

  def self.down
    remove_column :category_groups, :visible_in_calendar
  end
end
