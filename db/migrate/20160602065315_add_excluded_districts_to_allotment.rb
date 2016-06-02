class AddExcludedDistrictsToAllotment < ActiveRecord::Migration
  def change
    add_column :allotments, :excluded_district_ids, :integer, array: true, default: []
  end
end
