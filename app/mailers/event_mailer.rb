# Sends mail for actions concerning Events
class EventMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  # Sends an email to contacts when tickets have been released
  def ticket_release_notification_email(event, addresses, group_structure = nil)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(addresses)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Fördelade platser till #{event.name}")
    sent_on(Time.zone.now)
    body({ :event => event, :group_structure => group_structure, :category_groups => CategoryGroup.all })
  end

  # Sends an email to contacts when tickets transition to free for all allotment
  def free_for_all_allotment_notification_email(event, recipient)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(recipient)
    end

    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Restplatser till #{event.name}")
    sent_on(Time.zone.now)
    body({ :event => event, :category_groups => CategoryGroup.all })
  end

  # Sends an email to contacts when tickets transition to district allotment
  def district_allotment_notification_email(event, district, recipient)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(recipient)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Restplatser till #{event.name}")
    sent_on(Time.zone.now)
    body({ :event => event, :district => district, :category_groups => CategoryGroup.all })
  end

  # Sends a mail to the bus booking recipient with an event's bus bookings
  def bus_booking_email(event)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(APP_CONFIG[:mailers][:bus_booking_recipient])
    end

    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Kulturbussbokningar för #{event.name}")

    sent_on(Time.zone.now)
    content_type("multipart/mixed")

    part("multipart/alternative") do |alternative|
      alternative.part("text/html") do |html|
        html.body = render_message("bus_booking_email.text.html", :event => event)
      end
    end

    bookings = event.bookings.all(:conditions => { :bus_booking => true }, :include => :occasion, :order => "occasions.date, occasions.start_time")

    attachment(
      :content_type => "text/csv",
      :filename     => "bussbokning_evenemang#{event.id}.tsv",
      :body         => Booking.bus_booking_csv(bookings)
    )
  end
end
