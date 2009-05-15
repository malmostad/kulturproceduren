class CreateCultureProviders < ActiveRecord::Migration
  def self.up
    create_table :culture_providers do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :culture_providers
  end
end
