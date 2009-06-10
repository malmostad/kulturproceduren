class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.string  :name
      t.string  :filename
      t.integer :event_id
      t.integer :culture_provider_id

      t.timestamps
    end
  end

  def self.down
    drop_table :images
  end
end
