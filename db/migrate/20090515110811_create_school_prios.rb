class CreateSchoolPrios < ActiveRecord::Migration
  def self.up
    create_table :school_prios do |t|
      t.integer :prio
      t.integer :school_id
      t.integer :district_id

      t.timestamps
    end
  end

  def self.down
    drop_table :school_prios
  end
end
