class CreateOccasions < ActiveRecord::Migration
  def self.up
    create_table :occasions do |t|
      t.date :date
      t.integer :seats
      t.text :address
      t.text :description
      t.integer :event_id

      t.timestamps
    end
  end

  def self.down
    drop_table :occasions
  end
end
