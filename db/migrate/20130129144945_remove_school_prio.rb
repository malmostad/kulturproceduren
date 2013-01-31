class RemoveSchoolPrio < ActiveRecord::Migration
  def self.up
    drop_table :school_prios
  end

  def self.down
    create_table :school_prios do |t|
      t.integer :prio
      t.integer :school_id
      t.integer :district_id

      t.timestamps
    end
  end
end
