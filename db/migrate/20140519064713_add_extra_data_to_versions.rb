class AddExtraDataToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :extra_data, :text, default: ""
  end
end
