class AddBusBookingDetails < ActiveRecord::Migration
  def self.up
    add_column :events,  :bus_booking, :boolean, default: false

    add_column :bookings, :bus_booking, :boolean, default: false
    add_column :bookings, :bus_one_way, :boolean, default: false
    add_column :bookings, :bus_stop,    :string

    Event.update_all(  { bus_booking: false }, { bus_booking: nil })
    Booking.update_all({ bus_booking: false }, { bus_booking: nil })
  end

  def self.down
    remove_column :bookings, :bus_stop
    remove_column :bookings, :bus_one_way
    remove_column :bookings, :bus_booking

    remove_column :events, :bus_booking
  end
end
