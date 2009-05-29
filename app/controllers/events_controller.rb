class EventsController < ApplicationController
  layout "standard"
  require "pp"
  require 'rubygems'
  require 'gruff'

  def stats
    @event = Event.find_by_id(params[:id])
    @tickets_usage = gen_fname("tickets_usage")
    tott = Ticket.find(:all,:conditions => "event_id = #{@event.id}").length
    unbt = Ticket.find(:all,:conditions => "event_id = #{@event.id} and state = #{Ticket::UNBOOKED}").length
    unut = Ticket.find(:all,:conditions => "event_id = #{@event.id} and state = #{Ticket::NOT_USED}").length
    uset = Ticket.find(:all,:conditions => "event_id = #{@event.id} and (state = #{Ticket::USED} or state = #{Ticket::BOOKED} )").length

    g = Gruff::Pie.new(500)
    g.right_margin = 10
    g.left_margin = 10
    g.title_font_size = 30
    g.title = "Biljettanvändning för #{@event.name}"
    g.data  "Obokade biljetter", unbt
    g.data  "Oanvända biljetter", unut
    g.data  "Bokade/Använda biljetter" , uset
    g.write(@tickets_usage.to_s)
    @tickets_usage = @tickets_usage.sub("public","")

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

  def gen_fname(s)
    numpart = rand(10000)
    fname = "public/images/" + s + numpart.to_s + ".png"
    while File.exists?(fname) do
      numpart +=1
      fname = "public/images/" + s + numpart.to_s + ".png"
    end
    return fname
  end
end
