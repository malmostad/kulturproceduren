# Controller for managing occasions
class OccasionsController < ApplicationController

  layout "application"
  
  before_filter :authenticate, except: :show
  before_filter :require_culture_worker, only: [ :index, :edit, :update, :destroy, :cancel ]

  cache_sweeper :calendar_sweeper, only: [ :create, :update, :destroy, :cancel ]
  cache_sweeper :culture_provider_sweeper, only: [ :create, :update, :destroy, :cancel ]
  cache_sweeper :event_sweeper, only: [ :create, :update, :destroy, :cancel ]

  def index
    session[:last_occasion_added] ||= {}
    @occasion = Occasion.new(session[:last_occasion_added])
    @occasion.event = @event
  end

  # Displays a specific occasion as the part of an event presentation
  def show
    redirect_to Occasion.find(params[:id]).event
  end

  # Displays an editing form in place of the new occasion form in the
  # event presentation
  def edit
    render action: "index"
  end

  def create
    @occasion = Occasion.new(params[:occasion])
    @event = @occasion.event

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @event
      return
    end

    if @occasion.save
      session[:last_occasion_added] = params[:occasion]
      flash[:notice] = 'Föreställningen skapades.'
      redirect_to event_occasions_url(@event)
    else
      render action: "index"
    end
  end

  def update
    if @occasion.update_attributes(params[:occasion])
      flash[:notice] = 'Föreställningen uppdaterades.'
      redirect_to event_occasions_url(@event)
    else
      render action: "index"
    end
  end

  def destroy
    @occasion.destroy

    flash[:notice] = 'Föreställningen togs bort.'
    redirect_to event_occasions_url(@event)
  end

  def cancel
    @occasion.cancelled = true
    @occasion.save!

    OccasionMailer.occasion_cancelled_email(@occasion).deliver unless @occasion.users.empty?

    flash[:notice] = "Föreställningen ställdes in."
    redirect_to event_occasions_url(@occasion.event)
  end


  # Displays the ticket availability on the occasion's event
  def ticket_availability
    @occasion = Occasion.find(params[:id])
    @event = @occasion.event

    case @event.ticket_state
    when :alloted_group
      @entities = School.find_with_tickets_to_event(@event)
    when :alloted_district
      @entities = @event.districts.order "districts.name ASC"
    when :free_for_all
      nil
    else
      flash[:error] = "Platstillgänglighet kan inte presenteras för den önskade föreställningen."
      redirect_to root_url()
    end
  end


  private

  # Checks if the user has administration privileges on the occasion.
  # For use in <tt>before_filter</tt>.
  def require_culture_worker
    if params[:event_id] && params[:id]
      @event = Event.find(params[:event_id])
      @occasion = @event.occasions.find(params[:id])
    elsif params[:event_id]
      @event = Event.find(params[:event_id])
    elsif params[:id]
      @occasion = Occasion.find(params[:id])
      @event = @occasion.event
    end

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @event
    end
  end
end
