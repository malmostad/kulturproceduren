class AddAreaToSchool < ActiveRecord::Migration
  def change
    add_column :schools, :city_area, :text
    add_column :schools, :district_area, :text
  end
end
