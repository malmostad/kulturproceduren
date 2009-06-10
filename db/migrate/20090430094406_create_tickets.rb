class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets do |t|
      t.integer  :state
      t.integer  :group_id
      t.integer  :event_id
      t.integer  :occasion_id
      t.integer  :district_id
      t.integer  :companion_id
      t.boolean  :adult
      t.integer  :user_id
      t.boolean  :wheelchair , :default => false
      t.datetime :booked_when

      t.timestamps
    end
  end

  def self.down
    drop_table :tickets
  end
end
