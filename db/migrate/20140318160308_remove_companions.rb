class RemoveCompanions < ActiveRecord::Migration
  def up
  	remove_column :tickets, :companion_id
  	remove_column :answer_forms, :companion_id
  end

  def down
  	add_column :answer_forms, :companion_id, :integer
  	add_column :tickets, :companion_id, :integer
  end
end
