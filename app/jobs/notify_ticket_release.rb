class NotifyTicketRelease

  def run
    events = Event.where("ticket_release_date = current_date")
    events.each{ |e| process_event(e) }
  end


  def process_event_cultureworkers_only(event)
    puts "Notifying ticket release for #{event.name}."
    group_structure = {}
    school_structure = {}
    addresses = []

    Role.find_by_symbol(:admin).users.each { |u| addresses << u.email }

    case event.ticket_state
    when :alloted_group
      event.groups.each do |group|
        addresses += (group.school.contacts || "").split(",")
        #addresses += (group.school.district.contacts || "").split(",")
        group_structure[group.school] ||= []
        group_structure[group.school] << group
      end
    when :alloted_school
      addresses += (school.contacts || "").split(",")
      #addresses += (school.district.contacts || "").split(",")
      school_structure[school] ||= []
      school_structure[school] << school
    when :alloted_district
      event.districts.each do |district|
        #addresses += (district.contacts || "").split(",")
        district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
          addresses += (school.contacts || "").split(",")
        end
      end
    when :free_for_all_with_excluded_districts
      District.where.not(id: event.excluded_district_ids).each do |district|
        #addresses += (district.contacts || "").split(",")
        district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
          addresses += (school.contacts || "").split(",")
        end
      end
    when :free_for_all
      District.all.each do |district|
        #addresses += (district.contacts || "").split(",")
        district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
          addresses += (school.contacts || "").split(",")
        end
      end
    end

    addresses.collect! { |a| a.strip }
    addresses.reject! { |a| a !~ /\S+@\S+/ }
    addresses.uniq!

    addresses.each do |a|
      puts "Sending notification mail for ticket release about #{event.name} to #{a}."
      EventMailer.ticket_release_notification_email(event, [a], group_structure, school_structure).deliver
    end
  end

  def process_event(event)
    if [2438, 2455, 2459].include?(event.id)
      # Special handling, only send email to school contacts for these events.
      # process_event_cultureworkers_only(event)
      # Do nothing...
      expire_event_from_cache(event)
      return
    end

    puts "Notifying ticket release for #{event.name}"
    group_structure = {}
    school_structure = {}
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
      EventMailer.ticket_release_notification_email(event, [a], group_structure, school_structure).deliver
    end
    expire_event_from_cache(event)
  end

  def expire_event_from_cache(event)
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/administratable/reportable"

    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/administratable/reportable"

    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/administratable/reportable"

    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/administratable/reportable"
  end
end
