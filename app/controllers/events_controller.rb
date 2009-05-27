class EventsController < ApplicationController
  layout "standard"
  
  def index
    @events = Event.all :order => "created_at DESC", :include => :culture_provider
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
    @culture_providers = CultureProvider.all :order => "name ASC"
  end

  def edit
    @event = Event.find(params[:id])
    render :action => "new"
  end

  def create
    @event = Event.new(params[:event])

    if @event.save
      flash[:notice] = 'Evenemanget skapades.'
      redirect_to(@event)
    else
      render :action => "new"
    end
  end

  def update
    @event = Event.find(params[:id])

    if @event.update_attributes(params[:event])
      flash[:notice] = 'Evenemanget uppdaterades.'
      redirect_to(@event)
    else
      render :action => "new"
    end
  end

  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    flash[:notice] = "Evenemanget raderades."
    redirect_to(events_url)
  end
end
