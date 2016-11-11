class AddSchoolTransitionDateToEvent < ActiveRecord::Migration
  def change
    add_column :events, :school_transition_date, :date
  end
end
