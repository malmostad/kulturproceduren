class CreateAgeCategories < ActiveRecord::Migration
  def change
    create_table :age_categories do |t|
      t.string :name, limit: 40
      t.integer :from_age, null: false
      t.integer :to_age, null: false

      t.timestamps
    end

    AgeCategory.create!(name: 'Förskola', from_age: 1, to_age: 5)
    AgeCategory.create!(name: 'F-klass – skolår 3', from_age: 6, to_age: 9)
    AgeCategory.create!(name: 'Skolår 4-6', from_age: 10, to_age: 12)
    AgeCategory.create!(name: 'Skolår 7-9', from_age: 13, to_age: 15)
    AgeCategory.create!(name: 'Gymnasiet', from_age: 16, to_age: 19)
  end
end
