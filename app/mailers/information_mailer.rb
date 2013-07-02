# Sends information mails to recipients in the system
class InformationMailer < ActionMailer::Base
  layout "mail"

  default :from => APP_CONFIG[:mailers][:from_address]

  # Sends a custom mail
  def custom_email(address, subject, body)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = address
    end

    @message = body

    mail(
      :to      => recipients,
      :date    => Time.zone.now,
      :subject => subject
    )
  end
end
