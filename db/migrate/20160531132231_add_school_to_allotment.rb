class AddSchoolToAllotment < ActiveRecord::Migration
  def change
    add_reference :allotments, :school, index: true
  end
end
