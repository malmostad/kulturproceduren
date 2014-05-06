class CreateRoleApplications < ActiveRecord::Migration
  def self.up
    create_table :role_applications do |t|
      t.references :user, :role, :group, :culture_provider

      t.text :message
      t.text :new_culture_provider_name

      t.integer :state
      t.text :response

      t.timestamps
    end
  end

  def self.down
    drop_table :role_applications
  end
end
