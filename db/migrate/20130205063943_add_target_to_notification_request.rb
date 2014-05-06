class AddTargetToNotificationRequest < ActiveRecord::Migration
  def self.up
    # simple_enum column
    add_column :notification_requests, :target_cd, :integer
    NotificationRequest.update_all "target_cd = 1" # 1 = For transition
  end

  def self.down
    remove_column :notification_requests, :target_cd
  end
end
