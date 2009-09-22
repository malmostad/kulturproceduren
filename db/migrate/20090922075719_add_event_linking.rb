# Adds HABTM-joining of events.
class AddEventLinking < ActiveRecord::Migration
  def self.up
    create_table :event_links, :id => false do |t|
      t.integer :from_id
      t.integer :to_id
    end

    add_index :event_links, [ :from_id, :to_id ]
  end

  def self.down
    drop_table :event_links
  end
end
