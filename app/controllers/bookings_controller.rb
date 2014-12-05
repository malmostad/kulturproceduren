# Controller for managing bookings
class BookingsController < ApplicationController

  layout "application"

  before_filter :authenticate
  before_filter :require_admin, only: :bus
  before_filter :require_booker, except: [ :index, :apply_filter, :group, :group_list, :show ]
  before_filter :require_booking_viewer, only: [ :index, :apply_filter, :group, :group_list, :show ]
  before_filter :load_booking_for_change, only: [ :edit, :update, :unbook, :destroy ]

  cache_sweeper :calendar_sweeper, only: [ :create, :update, :destroy ]
  after_filter :sweep_culture_provider_cache, only: [ :create, :update, :destroy ]
  after_filter :sweep_event_cache, only: [ :create, :update, :destroy ]


  # Displays a list of a user's bookings
  def index
    session[:booking_list_filter] ||= {
      district_id: current_user.districts.first.try(:id)
    }

    if params[:occasion_id]
      @districts = District.order("name asc")
      @occasion = Occasion.find(params[:occasion_id])
      @bookings = Booking.find_for_occasion(params[:occasion_id], session[:booking_list_filter], params[:page])
    elsif params[:event_id]
      @districts = District.order("name asc")
      @event = Event.find(params[:event_id])
      @bookings = Booking.find_for_event(params[:event_id], session[:booking_list_filter], params[:page])
    else
      @bookings = Booking.active.find_for_user(current_user, session[:booking_list_filter], params[:page])
    end
  end

  # List of bus bookings for an event
  def bus
    @event = Event.find(params[:event_id])
    @bookings = @event.bookings.where(bus_booking: true).includes(:occasion).order("occasions.date, occasions.start_time")

    if params[:format] == "xls"
      send_csv(
        "bussbokning_evenemang#{@event.id}.tsv",
        Booking.bus_booking_csv(@bookings)
      )
    end
  end

  # Applies a filter for the occasion booking list
  def apply_filter
    filter = {}

    if params[:filter]
      filter[:district_id] = params[:district_id].to_i if !params[:district_id].blank? && params[:district_id].to_i > 0
      filter[:unbooked] = !params[:unbooked].blank?
      filter[:search] = params[:search] if !params[:search].blank?
    end

    session[:booking_list_filter] = filter

    if params[:occasion_id]
      redirect_to occasion_bookings_url(params[:occasion_id])
    elsif params[:event_id]
      redirect_to event_bookings_url(params[:event_id])
    else
      redirect_to bookings_url
    end
  end

  # Displays bookings by group
  def group
    load_group()
    
    if @group
      @bookings = Booking.active.find_for_group(@group, params[:page])
    end
  end

  # Returns a list of bookings for a group. For use in Ajax calls.
  def group_list
    @group = Group.includes(:school).find params[:group_id]
    @bookings = Booking.active.find_for_group(@group, 1)
    render partial: "list",
      content_type: "text/plain",
      locals: { bookings: @bookings }
  end

  # Displays a booking confirmation
  def show
    query = Booking
    query = Booking.active unless current_user.has_role?(:admin)
    @booking = query.includes(:occasion, group: :school).find params[:id]
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "Klassen/avdelningen har ingen bokning på den efterfrågade föreställningen."
    redirect_to bookings_url()
  end

  # Returns a form for creating/editing a booking. For use in Ajax calls.
  def form
    @group = Group.includes(:school).find params[:group_id]
    @occasion = Occasion.find(params[:occasion_id])

    @booking = Booking.active.where(group_id: @group.id, occasion_id: @occasion.id).first

    if @booking
      @is_edit = true
    else
      @booking = Booking.new do |b|
        b.group_id = @group.id if @group
        b.occasion_id = @occasion.id
      end
    end

    render partial: "form", content_type: "text/plain"
  end

  # Displays a form for creating a new booking
  def new
    @occasion = Occasion.find(params[:occasion_id])
    load_group()

    if @group
      @booking = Booking.active.where(group_id: @group.id, occasion_id: @occasion.id).first

      if @booking
        redirect_to edit_booking_url(@booking)
      else
        @booking = Booking.new do |b|
          b.group    = @group
          b.occasion = @occasion
        end

      end
    end
  end

  def create
    @booking = Booking.new(params[:booking])
    @booking.user = current_user
    @group = @booking.group

    @occasion = @booking.occasion

    if @booking.valid?
      Ticket.transaction do
        @booking.save!

        if @occasion.event.questionnaire
          answer_form = AnswerForm.new do |a|
            a.completed = false
            a.booking = @booking
            a.occasion = @occasion
            a.group = @group
            a.questionnaire = @occasion.event.questionnaire
          end

          answer_form.save!
        end
      end

      if unbooking_notification_request =
          NotificationRequest.unbooking_for(current_user, @occasion.event)
        unbooking_notification_request.destroy
      end

      flash[:notice] = "Platserna bokades."
      redirect_to booking_url(@booking)
    else
      render action: "new"
    end
  end

  # Displays a form for editing a booking
  def edit
    @group = @booking.group
    @occasion = @booking.occasion
    @is_edit = true

    render action: "new"
  end

  def update
    @booking.attributes = params[:booking]
    @booking.user = current_user

    @occasion = @booking.occasion

    if @booking.valid?
      old_available_tickets = @booking.event.unbooked_tickets
      was_fully_booked = @booking.event.fully_booked?

      Ticket.transaction do
        @booking.save!
      end

      if was_fully_booked && !@booking.event.fully_booked?(true) ||
          !was_fully_booked && old_available_tickets <= APP_CONFIG[:unbooking_notification_request_seat_limit]
        notify_requests_of_unbooking(@booking.event)
      end

      flash[:notice] = "Bokningen uppdaterades."
      redirect_to booking_url(@booking)
    else
      @is_edit = true
      @group = @booking.group
      render action: "new"
    end
  end

  # Displays the unbooking confirmation and questionnaire
  def unbook
    @questionnaire = Questionnaire.find_unbooking
    @answer = {}
  end

  # Unbooks a booking
  def destroy
    @occasion = @booking.occasion
    @questionnaire = Questionnaire.find_unbooking

    unless @questionnaire.questions.empty?
      @answer = params[:answer] || {}
      @answer_form = AnswerForm.new do |a|
        a.occasion = @occasion
        a.group = @booking.group
        a.questionnaire = @questionnaire
      end

      unless @answer_form.valid_answer?(@answer)
        render action: "unbook"
        return
      end
    end

    @booking.unbook!(current_user)

    if @answer_form
      @answer_form.booking = @booking
      @answer_form.answer(@answer) if @answer_form
    end

    notify_admins_of_unbooking(@booking, @answer_form)
    notify_requests_of_unbooking(@booking.event)

    flash[:notice] = "Platserna avbokades."
    redirect_to bookings_url()
  end


  private

  # Loads the requested booking, checking if it's possible to change it
  def load_booking_for_change
    @booking = Booking.active.find(params[:id])

    if @booking.occasion.cancelled || @booking.occasion.date < Date.today
      flash[:warning] = "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit"
      redirect_to booking_url(@booking)
    end
  end

  # Loads the requested group, either from an incoming id or
  # the group selection widget.
  def load_group
    if params[:group_id]
      @group = Group.includes(school: :district).find(params[:group_id])
      session[:group_selection] = {
        district_id: @group.school.district_id,
        school_id: @group.school.id,
        group_id: @group.id
      }
    elsif session[:group_selection] && session[:group_selection][:group_id]
      @group = Group.includes(school: :district).find session[:group_selection][:group_id]
    end
  end

  # Makes sure you can only book if you have booking privileges. For use in <tt>before_filter</tt>
  def require_booker
    if !current_user.can_book?
      if current_user.can_view_bookings?
        redirect_to action: "group"
      else
        flash[:error] = "Du har inte behörighet att komma åt sidan."
        redirect_to root_url()
      end
    end
  end
  # Makes sure you can only view bookings if you have viewing privileges. For use in <tt>before_filter</tt>
  def require_booking_viewer
    unless current_user.can_view_bookings?
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to root_url()
    end
  end

  # Clears the cache for a culture provider when a booking changes the amount
  # of free seats on an occasion.
  def sweep_culture_provider_cache
    if @occasion
      expire_fragment "culture_providers/show/#{@occasion.event.culture_provider.id}/upcoming_occasions/bookable"
    end
  end
  # Clears the cache for an event when a booking changes the amount
  # of free seats on an occasion.
  def sweep_event_cache
    if @occasion
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/not_bookable/not_administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/not_bookable/not_administratable/reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/not_bookable/administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/not_bookable/administratable/reportable"

      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/bookable/not_administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/bookable/not_administratable/reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/bookable/administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/not_online/bookable/administratable/reportable"

      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/not_bookable/not_administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/not_bookable/not_administratable/reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/not_bookable/administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/not_bookable/administratable/reportable"

      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/bookable/not_administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/bookable/not_administratable/reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/bookable/administratable/not_reportable"
      expire_fragment "events/show/#{@occasion.event.id}/occasion_list/online/bookable/administratable/reportable"
    end
  end


  def notify_admins_of_unbooking(booking, answer_form)
    BookingMailer.booking_cancelled_email(
      Role.find_by_symbol(:admin).users,
      current_user(),
      booking,
      answer_form
    ).deliver
  end

  def notify_requests_of_unbooking(event)
    if !event.fully_booked?(true) && event.unbooked_tickets(true) > APP_CONFIG[:unbooking_notification_request_seat_limit]
      event.notification_requests.for_unbooking.each do |req|
        NotificationRequestMailer.unbooking_notification(req).deliver
      end
    end
  end
end
