class AddBusBoosterSeatsCountToBooking < ActiveRecord::Migration
  def change
    add_column :bookings, :bus_booster_seats_count, :integer, default: 0
  end
end
