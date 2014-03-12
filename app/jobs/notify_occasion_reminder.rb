class NotifyOccasionReminder

  def initialize(today, occasion_reminder_days)
    @today, @occasion_reminder_days = today, occasion_reminder_days
  end


  def run
    # Do not notify on weekends
    if @today.wday > 0 && @today.wday < 6
      real_days = num_weekdays_to_real_days(@today.wday, @occasion_reminder_days)
      occasion_date = @today + real_days

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