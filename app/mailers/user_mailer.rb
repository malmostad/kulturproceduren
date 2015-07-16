class UserMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  default from: APP_CONFIG[:mailers][:from_address]

  # Sends an email requiring the user to confirm a password reset
  def password_reset_confirmation_email(user)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = user.email
    end

    @user = user

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Bekräfta återställning av lösenord"
    )
  end

  # Sends an email containing the user's new password
  def password_reset_email(user, password)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = user.email
    end

    @user     = user
    @password = password

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Nytt lösenord"
    )
  end

end
