# -*- encoding : utf-8 -*-
class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.references :event, :culture_provider
      t.string  :name
      t.string  :filename
      t.integer :width
      t.integer :height
      t.integer :thumb_width
      t.integer :thumb_height

      t.timestamps
    end

    add_column :events, :main_image_id, :integer
    add_column :culture_providers, :main_image_id, :integer
  end

  def self.down
    drop_table :images

    remove_column :events, :main_image_id
    remove_column :culture_providers, :main_image_id
  end
end
