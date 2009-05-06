class CreateCultureAdministrators < ActiveRecord::Migration
  def self.up
    create_table :culture_administrators do |t|
      t.string :name
      t.string :mobil_nr
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :culture_administrators
  end
end
