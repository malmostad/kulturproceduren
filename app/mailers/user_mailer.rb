class UserMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  # Sends an email requiring the user to confirm a password reset
  def password_reset_confirmation_email(user)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(user.email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Bekräfta återställning av lösenord")
    sent_on(Time.now)
    body({ :user => user })
  end

  # Sends an email containing the user's new password
  def password_reset_email(user, password)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(user.email)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Nytt lösenord")
    sent_on(Time.now)
    body({ :user => user, :password => password })
  end

end
