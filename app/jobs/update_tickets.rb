class UpdateTickets

  def run
    events = Event.where(ticket_state: [ Event::ALLOTED_GROUP, Event::ALLOTED_DISTRICT ])
    events.each{ |e| process_event(e) }
  end


  def process_event(e)
    notification_requests = []

    if e.transition_to_district?
      puts "Changing to district allotment for #{e.id}: #{e.name}"
      e.transition_to_district!

      if !e.fully_booked?
        puts "Notifying district allotment for #{e.id}: #{e.name}"

        districts = e.districts.where( " tickets.state = ? ", Ticket::UNBOOKED )
        notification_requests = NotificationRequest.for_transition.find_by_event_and_districts(e, districts)

        # Notify contacts on districts
        districts.each do |district|
          get_relevant_addresses(e, [district]).each do |address|
            puts "Sending notification mail for district allotment on #{e.name} to #{address}"
            EventMailer.district_allotment_notification_email(e, district, address).deliver
          end
        end

        # Send responses to notification requests
        notification_requests.each do |n|
          if n.send_mail
            puts "Notification request answered on #{e.name} to #{n.user.email}"
            NotificationRequestMailer.tickets_available_email(n, true).deliver
          end
        end
      end
    elsif e.transition_to_free_for_all?
      puts "Changing to free for all for #{e.id}: #{e.name}"
      e.transition_to_free_for_all!

      if !e.fully_booked?
        puts "Notifying free for all for #{e.id}: #{e.name}"
        notification_requests = NotificationRequest.for_transition.find_by_event(e)

        # Notify contacts on districts
        get_relevant_addresses(e, District.all).each do |address|
          puts "Sending notification mail for free for all on #{e.name} to #{address}"
          EventMailer.free_for_all_allotment_notification_email(e, address).deliver
        end

        # Send responses to notification requests
        notification_requests.each do |n|
          if n.send_mail
            puts "Notification request answered on #{e.name} to #{n.user.email}"
            NotificationRequestMailer.tickets_available_email(n, false).deliver
          end
        end
      end
    end

  end


  # Gets the relavant recipient addresses when sending mails for the ticket transitions.
  #
  # This method selects the contacts for the given district, and the schools and groups in
  # the districts that have children in the correct age groups.
  def get_relevant_addresses(event, districts)
    addresses = []

    Role.find_by_symbol(:admin).users.each { |u| addresses << u.email }

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
