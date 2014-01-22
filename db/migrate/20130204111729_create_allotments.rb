# -*- encoding : utf-8 -*-
class CreateAllotments < ActiveRecord::Migration
  def self.up
    create_table :allotments do |t|
      t.integer :amount
      t.references :user, :event, :district, :group
      t.timestamps
    end

    add_column :tickets, :allotment_id, :integer
  end

  def self.down
    remove_column :tickets, :allotment_id
    drop_table :allotments
  end
end
