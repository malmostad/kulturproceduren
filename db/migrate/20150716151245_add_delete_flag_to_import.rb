class AddDeleteFlagToImport < ActiveRecord::Migration
  def up
  	add_column :districts, :to_delete, :boolean
  	add_column :schools, :to_delete, :boolean
  	add_column :groups, :to_delete, :boolean
  	add_column :age_groups, :to_delete, :boolean
  end

  def down
  	remove_column :districts, :to_delete, :boolean
  	remove_column :schools, :to_delete, :boolean
  	remove_column :groups, :to_delete, :boolean
  	remove_column :age_groups, :to_delete, :boolean
  end
end
