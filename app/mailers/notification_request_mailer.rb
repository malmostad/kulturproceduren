# Mailer for actions concerning notification requests.
class NotificationRequestMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  default from: APP_CONFIG[:mailers][:from_address]

  # Sends an email when tickets have become available for
  # a group that has a registered notification request on the given
  # event
  def tickets_available_email(notification_request, district_release)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = notification_request.user.email
    end

    @notification_request = notification_request
    @district_release     = district_release
    @category_groups      = CategoryGroup.all

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Restplatser till #{notification_request.event.name}"
    )
  end

  def unbooking_notification(notification_request)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients = APP_CONFIG[:mailers][:debug_recipient]
    else
      recipients = notification_request.user.email
    end

    @notification_request = notification_request

    mail(
      to: recipients,
      date: Time.zone.now,
      subject: "Kulturkartan: Reservplatser till #{notification_request.event.name}"
    )
  end
end
