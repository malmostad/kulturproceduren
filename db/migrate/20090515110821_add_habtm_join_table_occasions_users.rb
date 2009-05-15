class AddHabtmJoinTableOccasionsUsers < ActiveRecord::Migration
  def self.up
    create_table :occasions_users, :id => false do |t|
      t.references :occasion, :user
    end
  end

  def self.down
    drop_table :occasions_users
  end
end
