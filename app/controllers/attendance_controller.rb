class AttendanceController < ApplicationController
  layout "application"

  before_filter :authenticate
  before_filter :load_entity

  before_filter :require_host, only: [ :report, :update_report ]

  # Lists the attendance of an event or a single occasion
  def index
    if params[:format] == "pdf"
      send_data generate_pdf().render, filename: "narvaro.pdf", type: "application/pdf", disposition: "inline"
    end
  end

  # Displays a form for reporting attendance
  def report
    if @occasion && @occasion.date >= Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to occasion_attendance_index_url(@occasion)
      return
    end

    if @event.is_external_event
      if !params[:booking_id].blank? and params[:booking_id] != '0'
        @booking = Booking.find(params[:booking_id].to_i)
      end
      render 'report_external'
    else
      render 'report'
    end
  end

  # Updates the attendance report
  def update_report
    if @occasion && @occasion.date >= Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to root_url()
      return
    end

    (@occasion ? [@occasion] : @event.reportable_occasions).each do |occasion|
      groups = occasion.attending_groups

      groups.each do |group|
        attendance = {}
        params[:attendance][occasion.id.to_s][group.id.to_s].each do |k,v|
          attendance[k.to_sym] = v.to_i unless v.blank?
        end

        tickets = Ticket.find_not_unbooked(group, occasion)

        tickets.each do |ticket|
          if ticket.adult
            if attendance.has_key?(:adult)
              ticket.state = attendance[:adult] > 0 ? :used : :not_used
              attendance[:adult] -= 1
            else
              ticket.state = :booked
            end
          elsif ticket.wheelchair
            if attendance.has_key?(:wheelchair)
              ticket.state = attendance[:wheelchair] > 0 ? :used : :not_used
              attendance[:wheelchair] -= 1
            else
              ticket.state = :booked
            end
          else
            if attendance.has_key?(:normal)
              ticket.state = attendance[:normal] > 0 ? :used : :not_used
              attendance[:normal] -= 1
            else
              ticket.state = :booked
            end
          end

          ticket.save!
        end

        # Create extra tickets for extra attendants
        [ :adult, :wheelchair, :normal ].each do |type|
          if attendance.has_key?(type) && attendance[type] > 0
            create_extra_tickets(attendance[type], tickets[0], type) 
          end
        end
      end
    end

    flash[:notice] = "Närvaron uppdaterades."
    if @occasion
      redirect_to report_occasion_attendance_index_url(@occasion)
    else
      redirect_to report_event_attendance_index_url(@event)
    end
  end

  # Updates the attendance report for external events
  def update_report_external
    date = params[:date]
    event_id = params[:event_id].to_i
    event = Event.find(event_id)
    group_id = params[:group_id].to_i
    student_count = params[:student].to_i
    adult_count = params[:adult].to_i
    wheelchair_count = params[:wheelchair].to_i
    booking_id = (params[:booking_id] || '0').to_i
    total_count = (student_count + adult_count + wheelchair_count)

    if booking_id > 0
      booking = Booking.find(booking_id)
      occasion = booking.occasion
      num_bookings = occasion.bookings.length
      tickets = Ticket.where(booking_id: booking_id).all
      tickets.each do |t|
        t.destroy!
      end
      booking.occasion.seats -= booking.student_count
      booking.occasion.seats -= booking.adult_count
      booking.occasion.wheelchair_seats -= booking.wheelchair_count
      booking.occasion.save!
      booking.destroy!
      if num_bookings == 1
        occasion.destroy!
      end
    end

    if total_count > 0
      if event
        occasion = event.occasions.where(date: date).where(cancelled: false).first
        if occasion.nil?
          occasion = Occasion.new do |o|
            o.event_id = event.id
            o.date = date
            o.start_time = '00:00'
            o.stop_time = '23:59'
            o.seats = 0
            o.wheelchair_seats = 0
            o.address = event.culture_provider.address || ''
            if o.address.blank? then o.address = 'Saknas' end
          end
        end
        occasion.seats += total_count
        occasion.wheelchair_seats += wheelchair_count
        occasion.save!

        booking = Booking.new do |b|
          b.occasion = occasion
          b.group = Group.find(group_id)
          b.user = current_user
          b.student_count = student_count
          b.adult_count = adult_count
          b.wheelchair_count = wheelchair_count
          b.companion_name = "*"
          b.companion_email = "*"
          b.companion_phone = "*"
        end

        booking.save!

        create_extra_external_tickets(booking, student_count, adult_count, wheelchair_count)

      end
    end

    redirect_to event_attendance_index_path(event)
  end

  protected

  # Loads either the requested event or the requested occasion
  def load_entity
    if !params[:event_id].blank?
      @event = Event.find params[:event_id]
    elsif !params[:occasion_id].blank?
      @occasion = Occasion.includes(:event).find(params[:occasion_id])
      @event = @occasion.event
    else
      flash[:error] = "Felaktig adress angiven"
      redirect_to root_url()
    end
  end

  # Checks if the user is a host. For use in <tt>before_filter</tt>.
  def require_host
    unless current_user.has_role?(:host) || current_user.has_role?(:admin)
      flash[:error] = "Du har inte behörighet att rapportera närvaro"
      redirect_to root_url()
      return
    end
  end

  private

  # Creates a pdf document of the attendants on an occasion or event
  def generate_pdf
    pdf = PDF::Writer.new paper: "A4", orientation: :landscape
    pdf.select_font("Helvetica")
    pdf.margins_cm(2, 2, 2, 2)

    (@occasion ? [ @occasion ] : @event.occasions).each do |occasion|
      PDF::SimpleTable.new do |tab|
        tab.title = "Deltagarlista för #{occasion.event.name}, föreställningen #{occasion.date.to_s} kl #{l(occasion.start_time, format: :only_time)}".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })

        tab.column_order.push(*%w(group comp att_normal att_adult att_wheel req pres_normal pres_adult pres_wheel))

        tab.columns["group"] = PDF::SimpleTable::Column.new("group") { |col|
          col.heading = "Skola / Grupp".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
          col.width = 130
        }
        tab.columns["comp"] = PDF::SimpleTable::Column.new("com") { |col|
          col.heading = "Medföljande vuxen".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
          col.width = 180
        }
        tab.columns["att_normal"] = PDF::SimpleTable::Column.new("att_normal") { |col|
          col.heading = "Barn"
        }
        tab.columns["att_adult"] = PDF::SimpleTable::Column.new("att_adult") { |col|
          col.heading = "Vuxna"
        }
        tab.columns["att_wheel"] = PDF::SimpleTable::Column.new("att_wheel") { |col|
          col.heading = "Rullstol"
        }
        tab.columns["req"]  = PDF::SimpleTable::Column.new("req") { |col|
          col.heading = "Övriga önskemål".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
          col.width = 130
        }
        tab.columns["pres_normal"]  = PDF::SimpleTable::Column.new("pres_normal") { |col|
          col.heading = "Barn".encode("ISO-8859-15")
        }
        tab.columns["pres_adult"]  = PDF::SimpleTable::Column.new("pres_adult") { |col|
          col.heading = "Vuxna".encode("ISO-8859-15")
        }
        tab.columns["pres_wheel"]  = PDF::SimpleTable::Column.new("pres_wheel") { |col|
          col.heading = "Rullstol".encode("ISO-8859-15")
        }

        tab.show_lines = :all
        tab.orientation = 1
        tab.position = :left
        tab.font_size = 9
        tab.heading_font_size = 9
        tab.maximum_width = 1
        tab.title_gap = 10
        tab.show_headings = true
        tab.heading_color = Color::RGB::White
        tab.shade_headings = true
        tab.shade_heading_color = Color::RGB::Grey30

        data = []

        occasion.bookings.school_ordered.each do |booking|
          data << create_pdf_row(occasion, booking)
        end

        if data.blank?
          # Add empty row
          data << {
            "group" => " ".encode("ISO-8859-15"),
            "comp" => " ".encode("ISO-8859-15"),
            "att_normal" => " ".encode("ISO-8859-15"),
            "att_adult" => " ".encode("ISO-8859-15"),
            "att_wheel" => " ".encode("ISO-8859-15"),
            "req" => " ".encode("ISO-8859-15"),
            "pres_normal" => " ".encode("ISO-8859-15"),
            "pres_adult" => " ".encode("ISO-8859-15"),
            "pres_wheel" => " ".encode("ISO-8859-15")
          }
        end

        tab.data.replace data
        tab.render_on(pdf)
      end
    end

    return pdf
  end

  def create_pdf_row(occasion, booking)
    row = {}
    row["group"] = (booking.group.school.name.to_s + " - " + booking.group.name.to_s).encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
    row["comp"] = "#{booking.companion_name}\n#{booking.companion_phone}\n#{booking.companion_email}".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
    row["att_normal"] = booking.student_count || 0
    row["att_adult"] = booking.adult_count || 0
    row["att_wheel"] = booking.wheelchair_count || 0
    row["req"] = (booking.requirement.blank? ? " " : booking.requirement).encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
    row["pres_normal"] = " ".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
    row["pres_adult"] = " ".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })
    row["pres_wheel"] = " ".encode("ISO-8859-15", {invalid: :replace, undef: :replace, replace: '?' })

    return row
  end

  # Creates extra tickets for unannounced attendants when reporting attendance
  def create_extra_tickets(attendance, base, type)
    1.upto(attendance) do |i|
      ticket = Ticket.new do |t|
        t.state = :used
        t.group = base.group
        t.user = current_user
        t.occasion = base.occasion
        t.event = base.event
        t.district = base.district
        t.booking = base.booking
        t.adult = (type == :adult)
        t.wheelchair = (type == :wheelchair)
        t.booked_when = Time.zone.now
      end

      ticket.save!
    end
  end

  def create_extra_external_tickets(booking, student_count, adult_count, wheelchair_count)
    total_count = student_count + adult_count + wheelchair_count

    1.upto(total_count) do |i|
      ticket = Ticket.new do |t|
        t.state = :used
        t.event = booking.event
        t.occasion = booking.occasion
        t.group = booking.group
        t.school = booking.group.school
        t.district = booking.group.school.district
        t.booking = booking
        t.user = current_user
        t.adult = (i > student_count && i <= (student_count + adult_count))
        t.wheelchair = (i > (student_count + adult_count) && i <= (student_count + adult_count + wheelchair_count))
        t.booked_when = Time.zone.now
      end

      ticket.save!
    end
  end

end
