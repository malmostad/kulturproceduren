# -*- encoding : utf-8 -*-
class AddRequestKeyAndLastActiveToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :last_active, :timestamp
    add_column :users, :request_key, :string
  end

  def self.down
    remove_column :users, :last_active
    remove_column :users, :request_key
  end
end
