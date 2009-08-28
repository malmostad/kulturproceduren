# Mailer for events surrounding role applications.
class RoleApplicationMailer < ActionMailer::Base
  layout 'mail'

  # Sends an email to administrators when a user has submitted a role application
  def application_submitted_email(role_application, administrators)
    recipients(administrators.map { |admin| admin.email })
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Behörighetsansökan inkommen")
    sent_on(Time.now)
    body({ :role_application => role_application })
  end

  # Sends an email to the user when an administrator has handled a role application
  def application_handled_email(role_application)
    recipients(role_application.user.email)
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Behörighetsansökan behandlad")
    sent_on(Time.now)
    body({ :role_application => role_application })
  end
end
