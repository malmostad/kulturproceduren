require "pp"
require 'rubygems'
require 'gruff'

class EventsController < ApplicationController
  layout "standard"

  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :check_roles, :except => [ :index, :show ]

  def stats
    @event = Event.find_by_id(params[:id])
    @tickets_usage = gen_fname("tickets_usage")
    tott = Ticket.find(:all,:conditions => "event_id = #{@event.id}").length
    unbt = Ticket.find(:all,:conditions => "event_id = #{@event.id} and state = #{Ticket::UNBOOKED}").length
    unut = Ticket.find(:all,:conditions => "event_id = #{@event.id} and state = #{Ticket::NOT_USED}").length
    uset = Ticket.find(:all,:conditions => "event_id = #{@event.id} and (state = #{Ticket::USED} or state = #{Ticket::BOOKED} )").length

    g = Gruff::Pie.new(400)
    g.right_margin = 10
    g.left_margin = 10
    g.title_font_size = 30
    g.title = "Biljettanvändning för #{@event.name}"
    g.data  "Obokade biljetter", unbt
    g.data  "Oanvända biljetter", unut
    g.data  "Bokade/Använda biljetter" , uset
    g.write(@tickets_usage.to_s)
    @tickets_usage = @tickets_usage.sub("public","")

    @og = []
    oi = 0
    @event.occasions.each do |o|
      @og[oi] = []
      qi = 0
      @event.questionaire.questions.each do |q|
        @og[oi][qi] = gen_fname("graf_occasion_" + o.date.to_s + "_question_" + q.id.to_s)
        answers = Answer.find(:all ,
          :conditions => {
            :occasion_id => o.id ,
            :question_id => q.id
          })
        histogram = []
        (0..4).each { |i| histogram[i] = 0 }
        answers.each { |a| histogram[a.answer-1] += 1 }
        g = Gruff::Bar.new(350)
        g.right_margin = 10
        g.left_margin = 10
        g.title_font_size = 30
        g.title = q.question.to_s
        g.sort = false
        (1..5).each { |n| g.data "#{n}" , histogram[ (n-1)] }
        g.write @og[oi][qi].to_s
        @og[oi][qi] = @og[oi][qi].sub("public","")
        qi += 1
      end
      oi += 1
    end
    render :stats
  end

  def index
    @events = Event.find :all,
      :conditions => [ "show_date <= ?", Date.today ],
      :order => "created_at DESC",
      :include => :culture_provider
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new do |e|
      e.to_age = 19
      e.culture_provider_id = params[:culture_provider_id] if params[:culture_provider_id]
    end

    load_culture_providers()
  end

  def edit
    @event = Event.find(params[:id])

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
      return
    end

    render :action => "new"
  end

  def create
    @event = Event.new(params[:event])

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
      return
    end

    load_culture_providers()

    if @event.save
      flash[:notice] = 'Evenemanget skapades.'
      redirect_to(@event)
    else
      render :action => "new"
    end
  end

  def update
    @event = Event.find(params[:id])

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
      return
    end

    if @event.update_attributes(params[:event])
      flash[:notice] = 'Evenemanget uppdaterades.'
      redirect_to(@event)
    else
      render :action => "new"
    end
  end

  def destroy
    @event = Event.find(params[:id])
    
    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
      return
    end

    @event.destroy

    flash[:notice] = "Evenemanget raderades."
    redirect_to(events_url)
  end


  private

  def load_culture_providers
    if current_user.has_role?(:admin)
      @culture_providers = CultureProvider.all :order => "name ASC"
    else
      @culture_providers = current_user.culture_providers.find :all, :order => "name ASC"
    end
  end

  def check_roles
    unless current_user.has_role?(:admin) || current_user.has_role?(:culture_worker)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
    end
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
