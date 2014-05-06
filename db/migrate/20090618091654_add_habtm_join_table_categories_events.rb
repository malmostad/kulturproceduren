class AddHabtmJoinTableCategoriesEvents < ActiveRecord::Migration
  def self.up
    create_table :categories_events, id: false do |t|
      t.references :category, :event
    end

    add_index :categories_events, [ :category_id, :event_id ], unique: true
  end

  def self.down
    drop_table :categories_events
  end
end
