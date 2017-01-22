class AddIsExternalEventToEvent < ActiveRecord::Migration
  def change
    add_column :events, :is_external_event, :boolean, default: false
  end
end
