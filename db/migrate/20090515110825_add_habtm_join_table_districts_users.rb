class AddHabtmJoinTableDistrictsUsers < ActiveRecord::Migration
  def self.up
    create_table :districts_users, :id => false do |t|
      t.references :district, :user
    end
  end

  def self.down
    drop_table :districts_users
  end
end
