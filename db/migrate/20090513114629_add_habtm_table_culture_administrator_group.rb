class AddHabtmTableCultureAdministratorGroup < ActiveRecord::Migration
  def self.up
    create_table :culture_administrators_users, :id => false do |t|
      t.references :culture_administrator, :user
    end
  end

  def self.down
    drop_table :culture_administrators_users
  end
end

