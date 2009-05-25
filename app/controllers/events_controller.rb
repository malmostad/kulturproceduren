class EventsController < ApplicationController
  layout "standard"
  
  # GET /events
  # GET /events.xml
  def index
    @events = Event.all
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    render :action => "new"
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])

    if @event.save
      flash[:notice] = 'Evenemanget skapades.'
      redirect_to(@event)
    else
      render :action => "new"
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])

    if @event.update_attributes(params[:event])
      flash[:notice] = 'Evenemanget uppdaterades.'
      redirect_to(@event)
    else
      render :action => "new"
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    redirect_to(events_url)
  end
end
