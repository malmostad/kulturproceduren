# -*- encoding : utf-8 -*-
class AddUserDistrictLink < ActiveRecord::Migration
  def self.up
    create_table :districts_users, :id => false do |t|
      t.references :district, :user
    end

    add_index :districts_users, [ :district_id, :user_id ],
      :name => "district_user_id"
  end

  def self.down
    drop_table :districts_users
  end
end
