# Sends mail for actions concerning Events
class EventMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  # Sends an email to contacts when tickets have been released
  def ticket_release_notification_email(event, addresses, group_structure = nil)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(addresses)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Fördelade platser till #{event.name}")
    sent_on(Time.now)
    body({ :event => event, :group_structure => group_structure, :category_groups => CategoryGroup.all })
  end

  # Sends an email to contacts when tickets transition to free for all allotment
  def free_for_all_allotment_notification_email(event, recipient)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(recipient)
    end

    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Möjligt att boka platser till #{event.name}")
    sent_on(Time.now)
    body({ :event => event, :category_groups => CategoryGroup.all })
  end

  # Sends an email to contacts when tickets transition to district allotment
  def district_allotment_notification_email(event, district, recipient)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(recipient)
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Bokningsbara platser till #{event.name}")
    sent_on(Time.now)
    body({ :event => event, :district => district, :category_groups => CategoryGroup.all })
  end
end
