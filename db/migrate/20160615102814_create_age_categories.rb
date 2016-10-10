class CreateAgeCategories < ActiveRecord::Migration
  def change
    create_table :age_categories do |t|
      t.string :name, limit: 40
      t.integer :from_age, null: false
      t.integer :to_age, null: false
      t.boolean :further_education, null: false, default: false
      t.integer :sort_order, null: false, default: 0

      t.timestamps
    end

    AgeCategory.create!(name: 'Förskola', from_age: 1, to_age: 5, further_education: false, sort_order: 1)
    AgeCategory.create!(name: 'F-klass – skolår 3', from_age: 6, to_age: 9, further_education: false, sort_order: 2)
    AgeCategory.create!(name: 'Skolår 4-6', from_age: 10, to_age: 12, further_education: false, sort_order: 3)
    AgeCategory.create!(name: 'Skolår 7-9', from_age: 13, to_age: 15, further_education: false, sort_order: 4)
    AgeCategory.create!(name: 'Gymnasiet', from_age: 16, to_age: 19, further_education: false, sort_order: 5)
    AgeCategory.create!(name: 'För pedagoger', from_age: 0, to_age: 100, further_education: true, sort_order: 6)
  end
end
