class CreateAgeGroups < ActiveRecord::Migration
  def self.up
    create_table :age_groups do |t|
      t.integer :age
      t.integer :quantity
      t.integer :group_id

      t.timestamps
    end
  end

  def self.down
    drop_table :age_groups
  end
end
