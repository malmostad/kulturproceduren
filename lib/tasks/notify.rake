# Tasks for sending notifications
namespace :kp do

  desc "Send reminder to companions for groups on upcoming occasions"
  task(notify_occasion_reminder: :environment) do
    NotifyOccasionReminder.new(Date.today, APP_CONFIG[:occasion_reminder_days]).run
  end

  desc "Sends a link to occasions' evaluation forms to the companion"
  task(send_answer_forms: :environment) do
    SendAnswerForms.new(Date.today, APP_CONFIG[:evaluation_form][:activation_days]).run
  end

  desc "Reminds a companion to fill in the evaluation form"
  task(remind_answer_form: :environment) do
    RemindAnswerForm.new(Date.today, APP_CONFIG[:evaluation_form][:reminder_days]).run
  end

  desc "Sends a notification for ticket release"
  task(notify_ticket_release: :environment) do
    event_id = ENV["event_id"]
    if !event_id.blank?
      puts "Processing event #{event_id}"
      tr = NotifyTicketRelease.new
      e = Event.find(event_id)

      if event_id == 2438 || event_id == 2455 || event_id == 2459
        # Special handling, only send email to school contacts for these events.
        tr.process_event_cultureworkers_only(e)
      else
        tr.process_event(e)
      end

      puts "Finished processing event #{event_id}"
    else
      NotifyTicketRelease.new.run
    end
  end

  desc "Send a reminder that tickets are still available to alloted recipients"
  task(notify_available_tickets: :environment) do
    NotifyAvailableTickets.new(Date.today, APP_CONFIG[:ticket_state][:reminder_weeks].to_i).run
  end

end

