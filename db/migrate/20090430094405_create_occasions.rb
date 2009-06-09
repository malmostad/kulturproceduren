class CreateOccasions < ActiveRecord::Migration
  def self.up
    create_table :occasions do |t|
      t.references :event
      t.date    :date
      t.time    :start_time
      t.time    :stop_time
      t.integer :seats
      t.integer :wheelchair_seats
      t.text    :address
      t.text    :description
      t.boolean :telecoil

      t.timestamps
    end
  end

  def self.down
    drop_table :occasions
  end
end
