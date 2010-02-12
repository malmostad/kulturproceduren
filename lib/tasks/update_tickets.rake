# Tasks for updating ticket states
namespace :kp do

  # Initializes the ticket state transition in events based on dates
  desc "Update ticket_state for events according to date"
  task(:update_tickets => :environment) do
    events = Event.find(:all, :conditions => { :ticket_state => [ Event::ALLOTED_GROUP, Event::ALLOTED_DISTRICT ] })
    
    events.each do |e|

      group_to_district_date = e.ticket_release_date + APP_CONFIG[:ticket_state][:group_days]
      district_to_all_date = group_to_district_date + APP_CONFIG[:ticket_state][:district_days]

      notification_requests = []

      if e.ticket_state == Event::ALLOTED_GROUP && group_to_district_date <= Date.today
        # Transition to districts
        e.ticket_state = Event::ALLOTED_DISTRICT
        e.save
        puts "Notifying district allotment for #{e.name}"

        districts = e.districts.find(:all, :conditions => [ " tickets.state = ? ", Ticket::UNBOOKED ])
        notification_requests = NotificationRequest.find_by_event_and_districts(e, districts)

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
            puts "Notification request answered on #{e.name} to #{address}"
            NotificationRequestMailer.deliver_tickets_available_email(n, true)
          end
        end
      elsif e.ticket_state == Event::ALLOTED_DISTRICT && district_to_all_date <= Date.today
        # Transistion to all
        e.ticket_state = Event::FREE_FOR_ALL
        state_change = Event::FREE_FOR_ALL
        e.save
        puts "Notifying free for all for #{e.name}"

        if e.tickets.count(:conditions => { :state => Ticket::UNBOOKED }) > 0
          notification_requests = NotificationRequest.find_by_event(e)

          # Notify contacts on districts
          get_relevant_addresses(e, District.all).each do |address|
            puts "Sending notification mail for free for all on #{e.name} to #{address}"
            EventMailer.deliver_free_for_all_allotment_notification_email(e, address)
          end
        end

        # Send responses to notification requests
        notification_requests.each do |n|
          if n.send_mail
            puts "Notification request answered on #{e.name} to #{address}"
            NotificationRequestMailer.deliver_tickets_available_email(n, false)
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
