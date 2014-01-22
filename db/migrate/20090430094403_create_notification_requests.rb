# -*- encoding : utf-8 -*-
class CreateNotificationRequests < ActiveRecord::Migration
  def self.up
    create_table :notification_requests do |t|
      t.references :event
      t.references :group
      t.references :user

      t.boolean :send_mail
      t.boolean :send_sms
      
      t.timestamps
    end
  end

  def self.down
    drop_table :notification_requests
  end
end
