# Tasks for updating ticket states
namespace :kp do

  # Initializes the ticket state transition in events based on dates
  desc "Update ticket_state for events according to date"
  task(:update_tickets => :environment) do
    events = Event.find(:all, :conditions => { :ticket_state => [ Event::ALLOTED_GROUP, Event::ALLOTED_DISTRICT ] })
    
    events.each do |e|

      notification_requests = []

      if e.alloted_group? && e.district_transition_date <= Date.today
        puts "Changing to district allotment for #{e.name}"
        # Transition to districts
        e.ticket_state = :alloted_district
        e.save

        if e.has_unbooked_tickets? && e.occasions.any? { |o| o.available_seats > 0 }
          puts "Notifying district allotment for #{e.name}"

          districts = e.districts.find(:all, :conditions => [ " tickets.state = ? ", Ticket::UNBOOKED ])
          notification_requests = NotificationRequest.for_transition.find_by_event_and_districts(e, districts)

          # Notify contacts on districts
          districts.each do |district|
            get_relevant_addresses(e, [district]).each do |address|
              puts "Sending notification mail for district allotment on #{e.name} to #{address}"
              EventMailer.deliver_district_allotment_notification_email(e, district, address)
            end
          end

          # Send responses to notification requests
          notification_requests.each do |n|
            if n.send_mail
              puts "Notification request answered on #{e.name} to #{n.user.email}"
              NotificationRequestMailer.deliver_tickets_available_email(n, true)
            end
          end
        end
      elsif e.alloted_district? && e.free_for_all_transition_date <= Date.today
        puts "Changing to free for all for #{e.name}"
        # Transistion to all
        e.ticket_state = :free_for_all
        e.save

        if e.has_unbooked_tickets? && e.occasions.any? { |o| o.available_seats > 0 }
          puts "Notifying free for all for #{e.name}"
          notification_requests = NotificationRequest.for_transition.find_by_event(e)

          # Notify contacts on districts
          get_relevant_addresses(e, District.all).each do |address|
            puts "Sending notification mail for free for all on #{e.name} to #{address}"
            EventMailer.deliver_free_for_all_allotment_notification_email(e, address)
          end

          # Send responses to notification requests
          notification_requests.each do |n|
            if n.send_mail
              puts "Notification request answered on #{e.name} to #{n.user.email}"
              NotificationRequestMailer.deliver_tickets_available_email(n, false)
            end
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
