# -*- encoding : utf-8 -*-
class AddHabtmJoinTableCultureProvidersUsers < ActiveRecord::Migration
  def self.up
    create_table :culture_providers_users, :id => false do |t|
      t.references :culture_provider, :user
    end
  end

  def self.down
    drop_table :culture_providers_users
  end
end
