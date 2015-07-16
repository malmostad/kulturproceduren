# Mailer for actions concerning occasions.
class OccasionMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer
  helper :application

  default from: APP_CONFIG[:mailers][:from_address]

  # Sends an email when an occasion is cancelled
  def occasion_cancelled_email(occasion)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = occasion.users.collect { |u| u.email }
    end

    @occasion = occasion

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Inställt evenemang - #{occasion.event.name}"
    )
  end

  # Sends a reminder email about the given occasion to the given companion
  def reminder_email(occasion, booking)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = booking.companion_email
    end

    @occasion = occasion
    @booking  = booking

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Snart dags för #{occasion.event.name}"
    )
  end

  # Sends a link to the answer form for the given occasion to the given booking's companion
  def answer_form_email(occasion, booking)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = booking.companion_email
    end

    @occasion = occasion
    @booking  = booking

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Utvärdering av #{occasion.event.name}"
    )
  end

  # Sends a reminder to fill in the answer form
  def answer_form_reminder_email(answer_form)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = answer_form.booking.companion_email
    end

    @answer_form = answer_form

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Påminnelse utvärdering - #{answer_form.occasion.event.name}"
    )
  end
end
