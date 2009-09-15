class NotificationRequestMailer < ActionMailer::Base
  # Sends an email when tickets have become available for
  # a group that has a registered notification request on the given
  # event
  def tickets_available_email(notification_request)
    recipients(notification_request.user.email)
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Platser tillgängliga")
    sent_on(Time.now)
    body({ :notification_request => notification_request })
  end
end
