# Mailer for actions concerning role applications.
class RoleApplicationMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  default from: APP_CONFIG[:mailers][:from_address]

  # Sends an email to administrators when a user has submitted a role application
  def application_submitted_email(role_application, administrators)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = administrators.map { |admin| admin.email }
    end

    @role_application = role_application

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Behörighetsansökan"
    )
  end

  # Sends an email to the user when an administrator has handled a role application
  def application_handled_email(role_application)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = role_application.user.email
    end

    @role_application = role_application

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Behörighet"
    )
  end
end
