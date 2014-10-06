class CreateEventsSchoolTypesTable < ActiveRecord::Migration
  def change
    create_table :events_school_types do |t|
      t.references :event
      t.references :school_type
    end
  end
end
