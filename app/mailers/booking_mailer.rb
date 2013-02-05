# Mailer for actions concerning bookings
class BookingMailer < ActionMailer::Base
  layout "mail"
  helper :mailer
  helper :application

  # Sends an email to administrators when a booking has been cancelled
  def booking_cancelled_email(administrators, user, group, occasion, answer_form)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(administrators.map { |admin| admin.email })
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Avbokning - #{group.name}, #{group.school.name} till #{occasion.event.name}")
    sent_on(Time.zone.now)
    body({ :user => user, :group => group, :occasion => occasion, :answer_form => answer_form })
  end
end
