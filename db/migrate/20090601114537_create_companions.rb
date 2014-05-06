class CreateCompanions < ActiveRecord::Migration
  def self.up
    create_table :companions do |t|
      t.string :tel_nr
      t.string :email
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :companions
  end
end
