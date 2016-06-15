class AddIndexOfLastTransionedDateToEvent < ActiveRecord::Migration
  def change
    add_index :events, :last_transitioned_date
  end
end
