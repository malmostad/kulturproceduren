# Tasks for sending bus bookings
namespace :kp do
  desc "Send bus booking lists to the administrators"
  task(send_bus_bookings: :environment) do
    SendBusBookings.new.run
  end
end
