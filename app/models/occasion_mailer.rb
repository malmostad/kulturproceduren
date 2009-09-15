class OccasionMailer < ActionMailer::Base
  layout 'mail'

  # Sends an email when an occasion is cancelled
  def occasion_cancelled_email(occasion, user)
    recipients(user.email)
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Föreställning inställd")
    sent_on(Time.now)
    body({ :occasion => occasion, :user => user, :groups => user.groups.find_by_occasion(occasion) })
  end

  # Sends a reminder email about the given occasion to the given companion
  def reminder_email(occasion, companion)
    recipients(companion.email)
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Påminnelse om föreställning")
    sent_on(Time.now)
    body({ :occasion => occasion, :companion => companion })
  end
end
