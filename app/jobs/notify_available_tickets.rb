class NotifyAvailableTickets

  def initialize(date, reminder_weeks)
    @date, @reminder_weeks = date, reminder_weeks
    @valid_last_transitioned_dates = [
      @date - (@reminder_weeks * 1 * 7),
      @date - (@reminder_weeks * 2 * 7),
      @date - (@reminder_weeks * 3 * 7),
      @date - (@reminder_weeks * 4 * 7),
      @date - (@reminder_weeks * 5 * 7),
      @date - (@reminder_weeks * 6 * 7),
      @date - (@reminder_weeks * 7 * 7),
      @date - (@reminder_weeks * 8 * 7),
      @date - (@reminder_weeks * 9 * 7),
      @date - (@reminder_weeks * 10 * 7)
    ]
  end

  def run
    events =
      Event.non_standing
        .where('visible_from <= ?', @date)
        .where('visible_to > ?', @date)
        .where.not(last_transitioned_date: nil)
        .where(last_transitioned_date: @valid_last_transitioned_dates)

    events.select {|e| e.has_available_seats? }.each { |e| process_event(e) }
  end

  def process_event(event)
    puts "Notifying available tickets for #{event.name}"
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
    when :alloted_school
      event.schools.each do |school|
        # Notify the contacts on both schools and districts
        addresses += (school.contacts || "").split(",")
        addresses += (school.district.contacts || "").split(",")

        school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
          addresses += (group.contacts || "").split(",")
        end

        school_structure[school] ||= []
        school_structure[school] << school
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
    when :free_for_all_with_excluded_districts
      District.where.not(id: event.excluded_district_ids).each do |district|
        addresses += (district.contacts || "").split(",")

        district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
          addresses += (school.contacts || "").split(",")

          school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
            addresses += (group.contacts || "").split(",")
          end
        end
      end
    when :free_for_all
      District.all.each do |district|
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
      EventMailer.tickets_available_notification_email(event, a, group_structure, school_structure).deliver
    end
  end
end
