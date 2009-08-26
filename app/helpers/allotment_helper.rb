module AllotmentHelper
  # Returns a CSS class indicating whether a row has a partial
  # or full allotment of tickets.
  def fill_indicator(num_children, num_tickets)
    if num_tickets > 0 && num_tickets < num_children
      return "partial"
    elsif num_tickets > 0 && num_tickets >= num_children
      return "full"
    end
  end

  # Returns a help text indicating describing the full or partial
  # or empty allotment of tickets
  def fill_indicator_text(num_children, num_tickets)
    if num_tickets > 0 && num_tickets < num_children
      return "Gruppen har blivit tilldelad biljetter, men färre än antalet barn i gruppen"
    elsif num_tickets > 0 && num_tickets >= num_children
      return "Gruppen har blivit tilldelad biljetter så att alla barn i gruppen får en biljett"
    else
      return "Gruppen har inte blivit tilldelad några biljetter"
    end
  end
end
