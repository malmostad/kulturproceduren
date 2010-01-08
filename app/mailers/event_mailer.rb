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
  def free_for_all_allotment_notification_email(event)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      recipients(get_relevant_addresses(event, District.all))
    end

    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Möjligt att boka platser till #{event.name}")
    sent_on(Time.now)
    body({ :event => event, :category_groups => CategoryGroup.all })
  end

  # Sends an email to contacts when tickets transition to district allotment
  def district_allotment_notification_email(event, district)
    if APP_CONFIG[:mailers][:debug_recipient]
      recipients(APP_CONFIG[:mailers][:debug_recipient])
    else
      #recipients(district.contacts.split(",")..collect { |c| c.strip }.uniq)
      recipients(get_relevant_addresses(event, [district]))
    end
    from(APP_CONFIG[:mailers][:from_address])
    subject("Kulturproceduren: Bokningsbara platser till #{event.name}")
    sent_on(Time.now)
    body({ :event => event, :district => district, :category_groups => CategoryGroup.all })
  end

  private

  # Gets the relavant recipient addresses when sending mails for the ticket transitions.
  #
  # This method selects the contacts for the given district, and the schools and groups in
  # the districts that have children in the correct age groups.
  def get_relevant_addresses(event, districts)
      addresses = []
      districts.each do |d|
        unless d.contacts.blank?
          addresses += d.contacts.split(",").collect { |c| c.strip }
        end

        d.schools.find_by_age_span(event.from_age, event.to_age).each do |s|
          unless s.contacts.blank?
            addresses += s.contacts.split(",").collect { |c| c.strip }
          end

          s.groups.find_by_age_span(event.from_age, event.to_age).each do |g|
            unless g.contacts.blank?
              addresses += g.contacts.split(",").collect { |c| c.strip }
            end
          end
        end
      end

      addresses.reject! { |a| a !~ /\S+@\S+/ }

      return addresses.uniq
  end
end
