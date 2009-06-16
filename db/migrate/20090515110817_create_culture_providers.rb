class CreateCultureProviders < ActiveRecord::Migration
  def self.up
    create_table :culture_providers do |t|
      t.string :name
      t.text   :description

      t.string :contact_person
      t.string :email
      t.string :phone
      t.text   :address
      # TODO coordinates?
      t.text   :opening_hours
      t.string :url
      
      t.timestamps
    end
  end

  def self.down
    drop_table :culture_providers
  end
end
