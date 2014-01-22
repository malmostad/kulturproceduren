# -*- encoding : utf-8 -*-
class CreateOccasions < ActiveRecord::Migration
  def self.up
    create_table :occasions do |t|
      t.references :event

      t.date    :date
      t.time    :start_time
      t.time    :stop_time

      t.integer :seats
      t.integer :wheelchair_seats, :default => 0

      t.text    :address
      t.text    :description
      t.boolean :telecoil

      t.boolean :cancelled, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :occasions
  end
end
