# Sends information mails to recipients in the system
class InformationMailer < ActionMailer::Base
  layout "mail"

  # Sends a custom mail
  def custom_email(address, subject, body)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(address)
    end

    from(APP_CONFIG[:mailers][:from_address])
    subject(subject)
    sent_on(Time.now)
    body({ :message => body })
  end
end
