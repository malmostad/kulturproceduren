class UserMailer < ApplicationMailer
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

    mail_from_app recipients, "Kulturkartan: Bekräfta återställning av lösenord"
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

    mail_from_app recipients, "Kulturkartan: Nytt lösenord"
  end

end
