class EventsController < ApplicationController
  layout "standard"
  require "pp"
  def stats


    @event = Event.find_by_id(params[:id])
    #TODO HELT FEL STATISTIK _ DUMHUVVE!!!!
    # 
    # Fördelning per föreställning av eventets totala biljettantall gårju inte!!!!

    i = 0
    @tot_ticks = Array.new
    @used_ticks = Array.new
    @unused_ticks = Array.new
    @unbooked_ticks = Array.new
    @event.occasions.each do |o|
      @tot_ticks[i] = Ticket.find(:all, :conditions =>"event_id = #{@event.id} and  occasion_id = #{o.id}").length
      next if @tot_ticks[i] == 0
      @used_ticks[i] = Ticket.find(:all, :conditions =>"event_id = #{@event.id} and occasion_id = #{o.id} and ( state = #{Ticket::USED} or state = #{Ticket::BOOKED})").length
      @unused_ticks[i] = Ticket.find(:all, :conditions =>"event_id = #{@event.id} and occasion_id = #{o.id} and state = #{Ticket::NOT_USED}").length
      @unbooked_ticks[i] = Ticket.find(:all, :conditions =>"event_id = #{@event.id} and occasion_id = #{o.id} and state = #{Ticket::UNBOOKED}").length
      i += 1
    end
    pp @tot_ticks
    pp @used_ticks
    pp @unused_ticks
    pp @unbooked_ticks
    render :stats
  end

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
