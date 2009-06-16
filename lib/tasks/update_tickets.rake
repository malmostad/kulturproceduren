namespace :kp do
  desc "Update ticket_state for events according to date"
  task( :update_tickets => :environment ) do
    Event.all.each do |e|
      state_change = nil

      if e.ticket_release_date + APP_CONFIG[:ticket_state_change_days] > Date.today
        e.ticket_state = Event::ALLOTED_DISTRICT
        state_change = Event::ALLOTED_DISTRICT
        e.save
      end

      if e.ticket_release_date + APP_CONFIG[:ticket_state_change_days] * 2 > Date.today
        e.ticket_state = Event::FREE_FOR_ALL
        state_change = Event::FREE_FOR_ALL
        e.save
      end
      
      if not state_change.nil?
        case state_change
        when Event::ALLOTED_DISTRICT
          puts "Evenemang #{e.name} är nu bokningsbart för hela stadsdelen"
        when Event::FREE_FOR_ALL
          puts "Evenemang #{e.name} är nu bokningsbart för alla"
        end
      end
    end
  end
  
end