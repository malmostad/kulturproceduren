class SendBusBookings
  def run
    events = Event.where(last_bus_booking_date: Date.yesterday)
    events.each { |e| process_event(e) }
  end

  def process_event(e)
    if e.has_bus_bookings?
      puts "Sending bus booking list for #{e.id}: #{e.name}"
      EventMailer.bus_booking_email(e).deliver
    end
  end
end
