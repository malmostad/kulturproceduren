# Tasks for sending notifications
namespace :kp do

  desc "Send reminder to companions for groups on upcoming occasions"
  task(:notify_occasion_reminder => :environment) do
    today = Date.today

    # Do not notify on weekends
    if today.wday > 0 && today.wday < 6
      real_days = num_weekdays_to_real_days(today.wday, APP_CONFIG[:occasion_reminder_days])
      occasion_date = today + real_days

      occasions = Occasion.find :all,
        :conditions => { :date => occasion_date, :cancelled => false },
        :include => :event

      # Notify for Saturday and Sunday when the targeted notification date is a Monday.
      if occasion_date.wday == 1
        occasions += Occasion.find :all,
          :conditions => { :date => occasion_date - 1, :cancelled => false },
          :include => :event
        occasions += Occasion.find :all,
          :conditions => { :date => occasion_date - 2, :cancelled => false },
          :include => :event
      end

      occasions.each do |occasion|
        occasion.bookings.active.each do |booking|
          OccasionMailer.reminder_email(occasion, booking).deliver
          puts "Sending mail about upcoming event #{occasion.event.name}, #{occasion.date} to #{booking.companion_email}"
        end
      end
    end
  end

  desc "Sends a link to occasions' evaluation forms to the companion"
  task(:send_answer_forms => :environment) do
    occasions = Occasion.find :all,
      :conditions => { :date => Date.today - APP_CONFIG[:evaluation_form][:activation_days], :cancelled => false },
      :include => :event
    
    occasions.each do |occasion|
      occasion.bookings.active.each do |booking|
        if booking.answer_form && !booking.answer_form.completed
          OccasionMailer.answer_form_email(occasion, booking).deliver
          puts "Sending mail about evaluation form for #{occasion.event.name}, #{occasion.date} to #{booking.companion_email}"
        end
      end
    end
  end

  desc "Reminds a companion to fill in the evaluation form"
  task(:remind_answer_form => :environment) do
    answer_forms = AnswerForm.find_overdue(Date.today - APP_CONFIG[:evaluation_form][:reminder_days])

    answer_forms.each do |answer_form|
      OccasionMailer.answer_form_reminder_email(answer_form).deliver
      puts "Sending reminder mail about evaluation form for #{answer_form.occasion.event.name}, #{answer_form.occasion.date} to #{answer_form.booking.companion_email}"
    end
  end

  desc "Sends a notification for ticket release"
  task(:notify_ticket_release => :environment) do
    events = Event.find :all, :conditions => "ticket_release_date = current_date"

    events.each do |event|
      puts "Notifying ticket release for #{event.name}"
      group_structure = {}
      addresses = []

      Role.find_by_symbol(:admin).users.each { |u| addresses << u.email }

      case event.ticket_state
      when :alloted_group
        event.groups.each do |group|
          # Notify the contacts on both groups, schools and districts
          addresses += (group.contacts || "").split(",")
          addresses += (group.school.contacts || "").split(",")
          addresses += (group.school.district.contacts || "").split(",")

          group_structure[group.school] ||= []
          group_structure[group.school] << group
        end
      when :alloted_district
        event.districts.each do |district|
          addresses += (district.contacts || "").split(",")

          district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
            addresses += (school.contacts || "").split(",")

            school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
              addresses += (group.contacts || "").split(",")
            end
          end
        end
      when :free_for_all
        District.find(:all).each do |district|
          addresses += (district.contacts || "").split(",")

          district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
            addresses += (school.contacts || "").split(",")

            school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
              addresses += (group.contacts || "").split(",")
            end
          end
        end
      end

      addresses.collect! { |a| a.strip }
      addresses.reject! { |a| a !~ /\S+@\S+/ }
      addresses.uniq!

      addresses.each do |a|
        puts "Sending notification mail for ticket release about #{event.name} to #{a}"
        EventMailer.ticket_release_notification_email(event,[a],group_structure).deliver
      end
    end
  end

  # Converts a number of weekdays to real days.
  # For use when calculating a date <tt>num_weekdays</tt> into the future.
  # 
  # Does not support starting on a weekend day (Saturday = 6, Sunday = 0).
  def num_weekdays_to_real_days(start_weekday, num_weekdays)
    real_days = 0
    current_weekday = start_weekday

    1.upto(num_weekdays) do |i|
      real_days += 1
      current_weekday += 1

      # Skip the weekend
      if current_weekday == 0 || current_weekday == 6
        real_days += 2
        current_weekday = 1
      end
    end

    return real_days
  end

end

