module OccasionHelper

  def booking_link(occasion)
    if user_online?
      if current_user.can_book?
        if occasion.event.bookable?
          available_seats = [ occasion.available_seats, occasion.event.unbooked_tickets ].min
          if available_seats > 0
            link_to "Boka", new_occasion_booking_path(occasion),
              title: "#{available_seats} lediga platser"
          else
            content_tag(:span, "Fullbokat", class: "sold-out")
          end
        end  
      end
    else
      if occasion.event.bookable?
        login_link "Kulturkartan", new_occasion_booking_path(occasion)
      else
        link_to "Arrangören", occasion.event
      end
    end
  end

  def ticket_availability_link(occasion)
    return "" unless user_online? && current_user.can_book? && occasion.event.bookable?

    link_to image_tag("information.png", alt: "Platstillgänglighet"),
      ticket_availability_occasion_path(occasion),
      class: "ticket-availability-link",
      title: "Platstillgänglighet för #{occasion.event.name} #{occasion.date} #{l occasion.start_time, format: :only_time}"
  end

end
