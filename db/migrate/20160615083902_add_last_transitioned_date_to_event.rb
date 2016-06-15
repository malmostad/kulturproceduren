class AddLastTransitionedDateToEvent < ActiveRecord::Migration
  def change
    add_column :events, :last_transitioned_date, :date
  end
end
