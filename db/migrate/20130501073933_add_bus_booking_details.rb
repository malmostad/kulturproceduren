class AddBusBookingDetails < ActiveRecord::Migration
  def self.up
    add_column :events,  :bus_booking, :boolean, default: false

    add_column :bookings, :bus_booking, :boolean, default: false
    add_column :bookings, :bus_one_way, :boolean, default: false
    add_column :bookings, :bus_stop,    :string

    Event.where(bus_booking: nil).update_all(bus_booking: false)
    Booking.where(bus_booking: nil).update_all(bus_booking: false)
  end

  def self.down
    remove_column :bookings, :bus_stop
    remove_column :bookings, :bus_one_way
    remove_column :bookings, :bus_booking

    remove_column :events, :bus_booking
  end
end
