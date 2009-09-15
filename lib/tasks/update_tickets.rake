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

        notification_requests = NotificationRequest.find_by_event_and_districts(
          e,
          e.districts.find(:all, :conditions => [ " tickets.state = ? ", Ticket::UNBOOKED ])
        )
      elsif e.ticket_state == Event::ALLOTED_DISTRICT && district_to_all_date <= Date.today
        e.ticket_state = Event::FREE_FOR_ALL
        state_change = Event::FREE_FOR_ALL
        e.save
        puts "Evenemang #{e.name} är nu bokningsbart för alla"

        if e.tickets.count(:conditions => { :state => Ticket::UNBOOKED }) > 0
          notification_requests = NotificationRequest.find_by_event(e)
        end
      end

      notification_requests.each do |n|
        if n.send_mail
          NotificationRequestMailer.deliver_tickets_available_email(n)
        end
      end
    end
  end

end
