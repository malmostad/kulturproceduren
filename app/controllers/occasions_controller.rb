# Controller for managing occasions
class OccasionsController < ApplicationController

  layout "standard"
  
  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :require_culture_worker, :only => [ :edit, :update, :destroy, :cancel ]

  cache_sweeper :calendar_sweeper, :only => [ :create, :update, :destroy, :cancel ]
  cache_sweeper :culture_provider_sweeper, :only => [ :create, :update, :destroy, :cancel ]
  cache_sweeper :event_sweeper, :only => [ :create, :update, :destroy, :cancel ]


  # Displays a specific occasion as the part of an event presentation
  def show
    @selected_occasion = Occasion.find(params[:id])
    @event = @selected_occasion.event
    @category_groups = CategoryGroup.all :order => "name ASC"

    render :template => "events/show"
  end

  # Displays an editing form in place of the new occasion form in the
  # event presentation
  def edit
    @event = @occasion.event
    @category_groups = CategoryGroup.all :order => "name ASC"
    render :template => "events/show"
  end

  def create
    @occasion = Occasion.new(params[:occasion])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
      return
    end

    if @occasion.save
      session[:last_occasion_added] = params[:occasion]
      flash[:notice] = 'Föreställningen skapades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      @category_groups = CategoryGroup.all :order => "name ASC"
      render :template => "events/show"
    end
  end

  def update
    if @occasion.update_attributes(params[:occasion])
      flash[:notice] = 'Föreställningen uppdaterades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      @category_groups = CategoryGroup.all :order => "name ASC"
      render :template => "events/show"
    end
  end

  def destroy
    @occasion.destroy

    flash[:notice] = 'Föreställningen togs bort.'
    redirect_to(@occasion.event)
  end

  def cancel
    @occasion.cancelled = true
    @occasion.save!

    OccasionMailer.deliver_occasion_cancelled_email(@occasion)

    flash[:notice] = "Föreställningen ställdes in."
    redirect_to(@occasion)
  end


  # Displays the ticket availability on the occasion's event. For use in an Ajax request.
  def ticket_availability
    @occasion = Occasion.find(params[:id], :include => { :event => :culture_provider })
    wrong_state = false

    case @occasion.event.ticket_state
    when Event::ALLOTED_GROUP
      @entities = School.find_with_tickets_to_event(@occasion.event)
    when Event::ALLOTED_DISTRICT
      @entities = @occasion.event.districts.find :all, :order => "districts.name ASC"
    when Event::FREE_FOR_ALL
      nil
    else
      wrong_state = true
    end

    if request.xhr? && wrong_state
      render :text => "", :content_type => "text/plain", :status => 404
    elsif request.xhr?
      render :partial => "ticket_availability_list", :content_type => "text/plain", :layout => false
    elsif wrong_state
      flash[:error] = "Platstillgänglighet kan inte presenteras för den önskade föreställningen."
      redirect_to root_url()
    end
  end


  private

  # Checks if the user has administration privileges on the occasion.
  # For use in <tt>before_filter</tt>.
  def require_culture_worker
    @occasion = Occasion.find(params[:id])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
    end
  end
end
