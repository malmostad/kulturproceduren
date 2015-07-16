# Sends mail for actions concerning Events
class EventMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  default from: APP_CONFIG[:mailers][:from_address]

  # Sends an email to contacts when tickets have been released
  def ticket_release_notification_email(event, addresses, group_structure = nil)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = addresses
    end

    @event           = event
    @group_structure = group_structure
    @category_groups = CategoryGroup.all

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Fördelade platser till #{event.name}"
    )
  end

  # Sends an email to contacts when tickets transition to free for all allotment
  def free_for_all_allotment_notification_email(event, recipient)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = recipient
    end

    @event           = event
    @category_groups = CategoryGroup.all

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Restplatser till #{event.name}"
    )
  end

  # Sends an email to contacts when tickets transition to district allotment
  def district_allotment_notification_email(event, district, recipient)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = recipient
    end

    @event           = event
    @district        = district
    @category_groups = CategoryGroup.all

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Restplatser till #{event.name}"
    )
  end

  # Sends a mail to the bus booking recipient with an event's bus bookings
  def bus_booking_email(event)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = APP_CONFIG[:mailers][:bus_booking_recipient]
    end

    @event = event

    bookings = event.bookings.where(bus_booking: true).includes(:occasion).order("occasions.date, occasions.start_time")

    attachments["bussbokning_evenemang#{event.id}.tsv"] = {
      mime_type: "text/csv",
      content: Booking.bus_booking_csv(bookings)
    }

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Kulturbussbokningar för #{event.name}"
    )
  end
end
