class AddAreaToSchool < ActiveRecord::Migration
  def change
    add_column :schools, :city_area, :string
    add_column :schools, :disctrict_area, :string
  end
end
