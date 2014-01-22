# -*- encoding : utf-8 -*-
class CreateBookingRequirements < ActiveRecord::Migration
  def self.up
    create_table :booking_requirements do |t|
      t.text :requirement
      t.integer :occasion_id
      t.integer :group_id

      t.timestamps
    end
  end

  def self.down
    drop_table :booking_requirements
  end
end
