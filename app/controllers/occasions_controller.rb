class OccasionsController < ApplicationController

  layout "standard"
  
  before_filter :authenticate, :except => [ :index, :show ]

  def attlist
    @occasion = Occasion.find(params[:id])
    if @occasion.nil?
      flash[:error] = "Felaktiga parametrar"
      redirect_to "/"
      return
    end
    
  end

  def index
    @today = Date.today

    @visible_events = Event.find( :all, :conditions => "show_date < '#{@today.to_s}'")
    @visible_occasions = []

    @visible_events.each do |e|
      o = Occasion.find(:all, :conditions => "event_id = #{e.id}")
      o.each do |oo|
        @visible_occasions.push(oo)
      end
    end

    @user = current_user
    @user_events = Event.visible_events_by_userid(@user.id)
    @user_events_hash_by_id = {}

    @user_events.each do |e|
      @user_events_hash_by_id[e.id] = e
    end

  end

  def show
    @selected_occasion = Occasion.find(params[:id])
    @event = @selected_occasion.event

    render :template => "events/show"
  end

  def edit
    @occasion = Occasion.find(params[:id])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
      return
    end

    @event = @occasion.event

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
      flash[:notice] = 'Föreställningen skapades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      render :template => "events/show"
    end
  end

  def update
    @occasion = Occasion.find(params[:id])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
      return
    end

    if @occasion.update_attributes(params[:occasion])
      flash[:notice] = 'Föreställningen uppdaterades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      render :template => "events/show"
    end
  end

  def destroy
    @occasion = Occasion.find(params[:id])

    if current_user.can_administrate?(@occasion.event.culture_provider)
      @occasion.destroy
    else
      flash[:error] = "Du har inte behörighet att komma åt sidan."
    end

    redirect_to(@occasion.event)
  end
end
