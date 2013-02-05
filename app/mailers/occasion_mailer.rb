# Mailer for actions concerning occasions.
class OccasionMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer
  helper :application

  # Sends an email when an occasion is cancelled
  def occasion_cancelled_email(occasion)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(occasion.users.collect { |u| u.email })
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Inställt evenemang - #{occasion.event.name}")
    sent_on(Time.zone.now)
    body({ :occasion => occasion })
  end

  # Sends a reminder email about the given occasion to the given companion
  def reminder_email(occasion, booking)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(booking.companion_email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Snart dags för #{occasion.event.name}")
    sent_on(Time.zone.now)
    body({ :occasion => occasion, :booking => booking })
  end

  # Sends a link to the answer form for the given occasion to the given booking's companion
  def answer_form_email(occasion, booking)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(booking.companion_email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Utvärdering av #{occasion.event.name}")
    sent_on(Time.zone.now)
    body({ :occasion => occasion, :booking => booking })
  end

  # Sends a reminder to fill in the answer form
  def answer_form_reminder_email(answer_form)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(answer_form.booking.companion_email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Påminnelse utvärdering - #{answer_form.occasion.event.name}")
    sent_on(Time.zone.now)
    body({ :answer_form => answer_form })
  end
end
