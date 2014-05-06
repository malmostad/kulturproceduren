class CreateBookings < ActiveRecord::Migration
  def self.up
    create_table :bookings do |t|
      t.datetime :booked_at
      t.boolean :unbooked, default: false
      t.datetime :unbooked_at
      t.integer :unbooked_by_id

      t.integer :student_count
      t.integer :adult_count
      t.integer :wheelchair_count

      t.text :requirement

      t.string :companion_name
      t.string :companion_phone
      t.string :companion_email

      t.references :group, :occasion, :user

      t.timestamps
    end

    # Add references to a booking to tickets and answer forms
    add_column :tickets, :booking_id, :integer
    add_column :answer_forms, :booking_id, :integer
  end

  def self.down
    remove_column :answer_forms, :booking_id
    remove_column :tickets, :booking_id

    drop_table :bookings
  end
end
