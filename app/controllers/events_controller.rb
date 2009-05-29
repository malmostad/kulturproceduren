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

    i = 0
    histogram = Array.new
    @occasion_answers = Array.new
    answers = Array.new
    pp @event
    pp @event.occasions
    @event.occasions.each do |o|
      puts "DEBUG o.id = #{o.id}"
      answers = Answer.find(:all , :conditions => "occasion_id = #{o.id}")
      puts "DEBUG: answers"
      puts "DEBUG: class = #{answers.class}"

      pp "#{answers}"
      if answers.length == 0
        @occasion_answers[i] = ""

      else
        @occasion_answers[i] = gen_fname("occasion_" + i.to_s  + "_")
        (0..5).each {|n| histogram[n] = 0 }
        answers.each do |a|
          pp a
          histogram[a.answer] +=1
          puts "DEBUG: answer id = #{a.id}"
          puts "DEBUG: answer = #{a.answer}"
        end
        puts "DEBUG: answers"
        pp answers
        puts "DEBUG: histogram"
        pp histogram
        g = Gruff::Bar.new(500)
        g.right_margin = 10
        g.left_margin = 10
        g.title_font_size = 30
        g.title = "Enkätsvar för föreställningen den #{o.date.to_s}"
        (1..5).each do |n|
          puts "Adding data to graph"
          puts "n = #{n} , histogram[n} = #{histogram[n]}"
          g.data "#{n}" , histogram[(n-1)]
        end
        puts "i = #{i} , Writing graph to filename #{@occasion_answers[i].to_s}"
        g.write @occasion_answers[i].to_s
        @occasion_answers[i] = @occasion_answers[i].sub("public","")
      end
      i += 1
    end
    pp @occasion_answer
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
