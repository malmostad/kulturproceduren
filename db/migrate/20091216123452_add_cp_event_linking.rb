class AddCpEventLinking < ActiveRecord::Migration
  def self.up
    create_table :culture_providers_events, :id => false do |t|
      t.references :culture_provider, :event
    end

    add_index :culture_providers_events, [ :culture_provider_id, :event_id ],
      :name => "cp_ev_id"
  end

  def self.down
    drop_table :culture_providers_events
  end
end
