class CreateNotificationRequests < ActiveRecord::Migration
  def self.up
    create_table :notification_requests do |t|
      t.boolean :send_mail
      t.boolean :send_sms
      t.integer :group_id
      t.integer :occasion_id

      t.timestamps
    end
  end

  def self.down
    drop_table :notification_requests
  end
end
