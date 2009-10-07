class EventMailer < ActionMailer::Base
  layout 'mail'

  # Sends an email to contacts when tickets have been released
  def ticket_release_notification_email(event, group, addresses)
    recipients(addresses)
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Tilldelade platser för #{event.name}")
    sent_on(Time.now)
    body({ :event => event, :group => group })
  end

  # Sends an email to contacts when tickets transition to free for all allotment
  def free_for_all_allotment_notification_email(event, district)
    recipients((district.contacts || "").split(",").collect { |c| c.strip })
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Platser för #{event.name} tillgängliga för alla")
    sent_on(Time.now)
    body({ :event => event, :district => district })
  end

  # Sends an email to contacts when tickets transition to district allotment
  def district_allotment_notification_email(event, district)
    recipients((district.contacts || "").split(",").collect { |c| c.strip })
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Platser för #{event.name} tillgängliga för stadsdelen")
    sent_on(Time.now)
    body({ :event => event, :district => district })
  end
end
