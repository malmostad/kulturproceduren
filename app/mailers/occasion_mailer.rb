class OccasionMailer < ActionMailer::Base
  layout 'mail'

  # Sends an email when an occasion is cancelled
  def occasion_cancelled_email(occasion, user)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(user.email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Inställt evenemang - #{occasion.event.name}")
    sent_on(Time.now)
    body({ :occasion => occasion })
  end

  # Sends a reminder email about the given occasion to the given companion
  def reminder_email(occasion, companion)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(companion.email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Snart dags för #{occasion.event.name}")
    sent_on(Time.now)
    body({ :occasion => occasion, :companion => companion })
  end

  # Sends a link to the answer form for the given occasion to the given companion
  def answer_form_email(occasion, companion)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(companion.email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Utvärdering av #{occasion.event.name}")
    sent_on(Time.now)
    body({ :occasion => occasion, :companion => companion })
  end

  # Sends a reminder to fill in the answer form
  def answer_form_reminder_email(answer_form)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(answer_form.companion.email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Påminnelse utvärdering - #{answer_form.occasion.event.name}")
    sent_on(Time.now)
    body({ :answer_form => answer_form })
  end
end
