class EventMailer < ActionMailer::Base
  layout 'mail'
  helper :mailer

  # Sends an email to contacts when tickets have been released
  def ticket_release_notification_email(event, group_structure, addresses)
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
  def free_for_all_allotment_notification_email(event, district)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients((district.contacts || "").split(",").collect { |c| c.strip })
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Platser för #{event.name} tillgängliga för alla")
    sent_on(Time.now)
    body({ :event => event, :district => district })
  end

  # Sends an email to contacts when tickets transition to district allotment
  def district_allotment_notification_email(event, district)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients((district.contacts || "").split(",").collect { |c| c.strip })
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Platser för #{event.name} tillgängliga för stadsdelen")
    sent_on(Time.now)
    body({ :event => event, :district => district })
  end
end
