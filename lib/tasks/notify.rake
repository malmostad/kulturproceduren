# Tasks for sending notifications
namespace :kp do

  desc "Send reminder to companions for groups on upcoming occasions"
  task(:notify_occasion_reminder => :environment) do
    today = Date.today

    # Do not notify on weekends
    if today.wday <= 5
      real_days = num_weekdays_to_real_days(today.wday, APP_CONFIG[:occasion_reminder_days])
      occasion_date = today + real_days

      occasions = Occasion.find :all,
        :conditions => { :date => occasion_date },
        :include => :event

      # Notify for Saturday and Sunday when the targeted notification date is a Monday.
      if occasion_date.wday == 1
        occasions += Occasion.find :all,
          :conditions => { :date => occasion_date - 1 },
          :include => :event
        occasions += Occasion.find :all,
          :conditions => { :date => occasion_date - 2 },
          :include => :event
      end

      occasions.each do |occasion|
        occasion.companions.each do |companion|
          OccasionMailer.deliver_reminder_email(occasion, companion)
          puts "Sending mail about upcomming event #{occasion.event.name} , #{occasion.date} to #{companion.email}"
        end
      end
    end
  end

  desc "Sends a link to occasions' evaluation forms to the companion"
  task(:send_answer_forms => :environment) do
    occasions = Occasion.find :all,
      :conditions => { :date => Date.today - APP_CONFIG[:evaluation_form][:activation_days] },
      :include => :event
    
    occasions.each do |occasion|
      occasion.companions.each do |companion|
        if companion.answer_form && !companion.answer_form.completed
          OccasionMailer.deliver_answer_form_email(occasion, companion)
          puts "Sending mail about evaluation form for #{occasion.event.name} , #{occasion.date} to #{companion.email}"
        end
      end
    end
  end

  desc "Reminds a companion to fill in the evaluation form"
  task(:remind_answer_form => :environment) do
    answer_forms = AnswerForm.find_overdue(Date.today - APP_CONFIG[:evaluation_form][:reminder_days])

    answer_forms.each do |answer_form|
      OccasionMailer.deliver_answer_form_reminder_email(answer_form)
      puts "Sending reminder mail about evaluation form for #{answer_form.occasion.event.name} , #{answer_form.occasion.date} to #{answer_form.companion.email}"
    end
  end

  desc "Sends a notification for ticket release"
  task(:notify_ticket_release => :environment) do
    events = Event.find :all, :conditions => "ticket_release_date = current_date"

    events.each do |event|
      puts "Notiferar kontakter att #{event.name} är fördelat"
      group_structure = {}
      addresses = []

      event.groups.each do |group|
        # Notify the contacts on both groups, schools and districts
        addresses += (group.contacts || "").split(",")
        addresses += (group.school.contacts || "").split(",")
        addresses += (group.school.district.contacts || "").split(",")

        group_structure[group.school] ||= []
        group_structure[group.school] << group
      end

      addresses.uniq!

      EventMailer.deliver_ticket_release_notification_email(event, group_structure, addresses.collect { |a| a.strip })
      addresses.each { |a| puts "Sending notification mail for ticket release about #{event.name} to #{a}" }
     
    end
  end


  # Converts a number of weekdays to real days.
  # For use when calculating a date <tt>num_weekdays</tt> into the future.
  def num_weekdays_to_real_days(start_weekday, num_weekdays)
    case start_weekday
    when 1..5
      # Start counting on the given start date when it is a regular week day
      real_days = 0
      current_weekday = start_weekday
    when 6
      # Start counting on the Monday when the real start date is a Saturday,
      # and include the number of skipped days in the number of real days.
      real_days = 2
      current_weekday = 1
    when 7
      # Start counting on the Monday when the real start date is a Sunday,
      # and include the number of skipped days in the number of real days.
      real_days = 1
      current_weekday = 1
    end

    1.upto(num_weekdays) do |i|
      real_days += 1
      current_weekday += 1

      # Skip the weekend
      if current_weekday > 5
        real_days += 2
        current_weekday = 1
      end
    end

    return real_days
  end
end

