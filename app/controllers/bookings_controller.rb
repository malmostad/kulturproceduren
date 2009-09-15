# Controller for managing bookings
class BookingsController < ApplicationController

  layout "standard"

  before_filter :authenticate
  before_filter :require_booker
  before_filter :load_occasion, :except => [ :index, :group, :group_list ]
  before_filter :load_group, :except => [ :index, :form, :group_list ]

  # Displays a list of a user's bookings
  def index
    @bookings = Ticket.find_user_bookings(current_user, params[:page])
  end

  # Displays bookings by group
  def group
    load_group_selection_collections()
    
    if @group
      @bookings = Ticket.find_group_bookings(@group, params[:page])
    end
  end

  # Returns a list of bookings for a group. For use in Ajax calls.
  def group_list
    @group = Group.find params[:group_id], :include => :school
    @bookings = Ticket.find_group_bookings(@group, 1)
    render :partial => "list",
      :content_type => "text/plain",
      :locals => { :bookings => @bookings }
  end

  # Displays a booking confirmation
  def show
    @booking = Ticket.booking(@group, @occasion)

    if @booking.values.inject { |sum, n| sum += n } == 0
      flash[:warning] = "Gruppen har ingen bokning på den efterfrågade föreställningen."
      redirect_to root_url()
      return
    end

    @companion = Companion.get(@group, @occasion)
    @booking_requirement = BookingRequirement.get(@group, @occasion)
  end

  # Returns a form for creating/editing a booking. For use in Ajax calls.
  def form
    @group = Group.find params[:group_id], :include => :school
    @seats = {}
    @companion = Companion.new
    @booking_requirement = BookingRequirement.new

    render :partial => "form", :content_type => "text/plain"
  end

  # Displays a form for creating a new booking
  def new
    if @group && @group.booked_tickets_by_occasion(@occasion) > 0
      # Redirect to the edit interface if a booking already exists
      redirect_to edit_occasion_booking_url(@occasion.id, @group.id)
    else
      load_group_selection_collections(@occasion)
      @seats = {}
      @companion = Companion.new
      @booking_requirement = BookingRequirement.new
    end
  end

  def create
    @seats = params[:seats]
    @companion = Companion.new(params[:companion])
    load_booking_requirement(params[:booking_requirements])

    # Validate the incoming data
    valid = validate_seats(@seats)
    valid = @companion.valid? && valid

    if valid
      begin
        Ticket.transaction do
          # Create booking data objects
          @companion.save!

          if @occasion.event.questionaire
            answer_form = AnswerForm.new do |a|
              a.completed = false
              a.companion = @companion
              a.occasion = @occasion
              a.group = @group
              a.questionaire = @occasion.event.questionaire
            end

            answer_form.save!
          end

          @booking_requirement.save! unless @booking_requirement.requirement.blank?

          # Create tickets
          tickets = @group.bookable_tickets(@occasion, true)

          book_tickets(tickets, :normal)
          book_tickets(tickets, :adult)
          book_tickets(tickets, :wheelchair)
        end

        # Delete all notification requests for the given event and group
        NotificationRequest.find_by_event_and_group(@occasion.event, @group).each { |n| n.destroy }

        flash[:notice] = "Platserna bokades."
        redirect_to occasion_booking_url(@occasion.id, @group.id)

      rescue Exception => ex
        puts "\n\n\n\n\n\n\n\n#{ex.to_yaml}\n\n\n\n\n\n\n\n\n"
        flash[:error] = "Ett fel uppstod när platserna skulle bokas. Var god försök igen senare."
        redirect_to new_occasion_booking_url(@occasion)
      end
    else
      load_group_selection_collections(@occasion)
      @is_error = true

      render :action => "new"
    end
  end

  # Displays a form for editing a booking
  def edit
    if @group && @group.booked_tickets_by_occasion(@occasion) <= 0
      # Redirect to the booking creation form if there is no existing booking
      # for the given occasion and group
      redirect_to new_occasion_booking(@occasion)
    else
      @is_edit = true
      load_group_selection_collections(@occasion)

      @seats = Ticket.booking(@group, @occasion)
      @companion = Companion.get(@group, @occasion)

      load_booking_requirement()

      render :action => "new"
    end
  end

  def update
    @seats = params[:seats]
    current_booking = Ticket.booking(@group, @occasion)

    @companion = Companion.get(@group, @occasion)
    @companion.attributes = @companion.attributes.merge(params[:companion])

    load_booking_requirement(params[:booking_requirement])

    valid = validate_seats(
      @seats,
      current_booking[:normal] + current_booking[:adult] + current_booking[:wheelchair],
      current_booking[:wheelchair]
    )
    valid = @companion.valid? && valid

    if valid
      begin
        Ticket.transaction do
          # Create booking data objects
          @companion.save!

          if @booking_requirement.requirement.blank?
            @booking_requirement.destroy unless @booking_requirement.new_record?
          else
            @booking_requirement.save! 
          end

          # Get the difference in requested seats between the old booking and
          # the incoming request
          booking_diff = {}
          @seats.keys.each { |k| booking_diff[k.to_sym] = @seats[k.to_sym].to_i - current_booking[k.to_sym].to_i }

          # Unbook tickets if the difference between the existing booking and the
          # incoming change is negative
          unbook_tickets(-booking_diff[:normal], :normal) if booking_diff[:normal] < 0
          unbook_tickets(-booking_diff[:adult], :adult) if booking_diff[:adult] < 0
          unbook_tickets(-booking_diff[:wheelchair], :wheelchair) if booking_diff[:wheelchair] < 0

          # Create tickets if the user requests more tickets
          tickets = @group.bookable_tickets(@occasion, true)
          @seats = booking_diff
          book_tickets(tickets, :normal) if booking_diff[:normal] > 0
          book_tickets(tickets, :adult) if booking_diff[:adult] > 0
          book_tickets(tickets, :wheelchair) if booking_diff[:wheelchair] > 0

          # Update all booked tickets for the group to the occasion
          # to change the booker to the current user
          Ticket.update_all(
            { :user_id => current_user.id },
            {
            :group_id => @group.id,
            :occasion_id => @occasion.id,
            :state => Ticket::BOOKED
          })
        end

        flash[:notice] = "Platserna bokades."
        redirect_to occasion_booking_url(@occasion.id, @group.id)

      rescue Exception
        flash[:error] = "Ett fel uppstod när platserna skulle bokas. Var god försök igen senare."
        redirect_to new_occasion_booking_url(@occasion)
      end
    else
      @is_edit = true
      @is_error = true
      load_group_selection_collections(@occasion)

      render :action => "new"
    end
  end

  # Unbooks a booking
  def destroy
    tickets = Ticket.find_booked(@group, @occasion)
    tickets.each { |ticket| unbook_ticket(ticket) }

    flash[:notice] = "Platserna avbokades."
    redirect_to bookings_url()
  end


  private

  # Books tickets of a given type. The number of tickets
  # booked is fetched from the seats parameter.
  def book_tickets(tickets, type)
    1.upto(@seats[type].to_i) do |i|
      ticket = tickets.pop

      ticket.state = Ticket::BOOKED
      ticket.group = @group
      ticket.companion = @companion
      ticket.user = current_user
      ticket.occasion = @occasion
      ticket.wheelchair = (type == :wheelchair)
      ticket.adult = (type == :adult)
      ticket.booked_when = DateTime.now

      ticket.save!
    end
  end

  # Unbooks +num+ tickets of a given type.
  def unbook_tickets(num, type)
    tickets = Ticket.find_booked_by_type(@group, @occasion, type)
    1.upto(num) do |i|
      ticket = tickets.pop
      unbook_ticket(ticket)
    end
  end

  # Unbooks a ticket
  def unbook_ticket(ticket)
    ticket.state = Ticket::UNBOOKED
    ticket.companion = nil
    ticket.user = nil
    ticket.occasion = nil
    ticket.wheelchair = false
    ticket.adult = false
    ticket.booked_when = nil

    ticket.save!
  end

  # Validates the number of seats the user is trying to book.
  #
  # The validation can be tweaked allowing extra tickets and extra wheel
  # chair tickets to be added to the amount of avaliable tickets
  def validate_seats(seats, extra_tickets = 0, extra_wheelchair_tickets = 0)
    valid = true
    @seats_errors = {}

    ticket_sum = seats[:normal].to_i + seats[:adult].to_i + seats[:wheelchair].to_i
    available_tickets = @group.available_tickets_by_occasion(@occasion).to_i 
    available_wheelchair_tickets = @occasion.available_wheelchair_seats

    if ticket_sum <= 0
      @seats_errors[:normal] = "Du måste boka minst 1 plats"
      valid = false
    elsif available_tickets + extra_tickets < ticket_sum
      @seats_errors[:normal] = "Du har bara #{available_tickets} platser du kan boka på den här föreställningen"
      valid = false
    elsif available_wheelchair_tickets + extra_wheelchair_tickets < seats[:wheelchair].to_i
      @seats_errors[:wheelchair] = "Det finns bara #{available_wheelchair_tickets} rullstolsplatser du kan boka på den här föreställningen"
    end

    return valid
  end

  # Loads the requested occasion
  def load_occasion
    @occasion = Occasion.find params[:occasion_id], :include => :event
  rescue
    flash[:warning] = "Du måste välja en föreställning"
    redirect_to root_url()
  end

  # Loads the requested group, either from an incoming id or
  # the group selection widget.
  def load_group
    if params[:id]
      @group = Group.find params[:id], :include => { :school => :district }
      session[:group_selection] = {
        :district_id => @group.school.district_id,
        :school_id => @group.school.id,
        :group_id => @group.id
      }
    elsif session[:group_selection] && session[:group_selection][:group_id]
      @group = Group.find session[:group_selection][:group_id],
        :include => { :school => :district }
    end
  end

  # Makes sure you can only book if you have booking privileges. For use in +before_filter+
  def require_booker
    unless current_user.can_book?
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to root_url()
    end
  end

  # Tries to load a booking requirement from the incoming parameters,
  # and if none exist, a new instance is created with the given values
  def load_booking_requirement(values = nil)
    @booking_requirement = BookingRequirement.get(@group, @occasion)

    if @booking_requirement
      @booking_requirement.attributes = @booking_requirement.attributes.merge(values) unless values.nil?
    else
      @booking_requirement = BookingRequirement.new(values)
      @booking_requirement.occasion = @occasion
      @booking_requirement.group = @group
    end
  end
end
