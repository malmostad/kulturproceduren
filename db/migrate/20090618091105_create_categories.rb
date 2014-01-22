# -*- encoding : utf-8 -*-
class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.references :category_group
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :categories
  end
end
