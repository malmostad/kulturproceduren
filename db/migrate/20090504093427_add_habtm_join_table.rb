class AddHabtmJoinTable < ActiveRecord::Migration
  def self.up
    create_table :culture_administrator_group, :id => false do |t|
      t.references :culture_administrator, :group
    end
  end

  def self.down
    drop_table :culture_administrator_group
  end
end
