class NotifyTicketRelease

  def run
    events = Event.find :all, conditions: "ticket_release_date = current_date"
    events.each{ |e| process_event(e) }
  end


  def process_event(event)
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
