class AddExcludedDistrictsToEvent < ActiveRecord::Migration
  def change
    add_column :events, :excluded_district_ids, :integer, array: true, default: []
  end
end
