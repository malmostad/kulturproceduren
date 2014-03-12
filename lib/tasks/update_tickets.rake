# -*- coding: utf-8 -*-
# Tasks for updating ticket states
namespace :kp do

  # Initializes the ticket state transition in events based on dates
  desc "Update ticket_state for events according to date"
  task(:update_tickets => :environment) do
    UpdateTickets.new.run
  end

  
end
