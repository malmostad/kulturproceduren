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
        e.ticket_state = Event::ALLOTED_DISTRICT
        e.save
        puts "Evenemang #{e.name} är nu bokningsbart för hela stadsdelen"

        districts = e.districts.find(:all, :conditions => [ " tickets.state = ? ", Ticket::UNBOOKED ])
        notification_requests = NotificationRequest.find_by_event_and_districts(e, districts)

        districts.each do |district|
          EventMailer.deliver_district_allotment_notification_email(e, district)
        end

        notification_requests.each do |n|
          if n.send_mail
            NotificationRequestMailer.deliver_tickets_available_email(n, true)
          end
        end
      elsif e.ticket_state == Event::ALLOTED_DISTRICT && district_to_all_date <= Date.today
        e.ticket_state = Event::FREE_FOR_ALL
        state_change = Event::FREE_FOR_ALL
        e.save
        puts "Evenemang #{e.name} är nu bokningsbart för alla"

        if e.tickets.count(:conditions => { :state => Ticket::UNBOOKED }) > 0
          notification_requests = NotificationRequest.find_by_event(e)
          EventMailer.deliver_free_for_all_allotment_notification_email(e)
        end

        notification_requests.each do |n|
          if n.send_mail
            NotificationRequestMailer.deliver_tickets_available_email(n, false)
          end
        end
      end

    end
  end

end
