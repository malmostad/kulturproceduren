class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets do |t|
      t.integer :state
      t.integer :group_id
      t.integer :event_id
      t.integer :occasion_id
      t.integer :district_id

      t.timestamps
    end
  end

  def self.down
    drop_table :tickets
  end
end
