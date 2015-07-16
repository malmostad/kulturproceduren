# Mailer for actions concerning bookings
class BookingMailer < ActionMailer::Base
  layout "mail"
  helper :mailer
  helper :application

  default from: APP_CONFIG[:mailers][:from_address]

  # Sends an email to administrators when a booking has been cancelled
  def booking_cancelled_email(administrators, user, booking, answer_form)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = administrators.map { |admin| admin.email }
    end

    @user        = user
    @booking     = booking
    @answer_form = answer_form

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Avbokning - #{booking.group.name}, #{booking.group.school.name} till #{booking.occasion.event.name}"
    )
  end
end
