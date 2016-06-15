class CreateAgeCategories < ActiveRecord::Migration
  def change
    create_table :age_categories do |t|
      t.string :name, limit: 40
      t.integer :from_age, null: false
      t.integer :to_age, null: false

      t.timestamps
    end
  end
end
