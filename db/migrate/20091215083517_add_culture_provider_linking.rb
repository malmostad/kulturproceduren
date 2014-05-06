# -*- encoding : utf-8 -*-
class AddCultureProviderLinking < ActiveRecord::Migration
  def self.up
    create_table :culture_provider_links, id: false do |t|
      t.integer :from_id
      t.integer :to_id
    end

    add_index :culture_provider_links, [ :from_id, :to_id ]
  end

  def self.down
    drop_table :culture_provider_links
  end
end
