class AddLastBusBookingDateToEvents < ActiveRecord::Migration
  def change
    add_column :events, :last_bus_booking_date, :date
  end
end
