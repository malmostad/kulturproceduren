require "pp"
require 'rubygems'
require 'gruff'

# Controller for managing events
class EventsController < ApplicationController
  layout "standard", :except => [ :options_list ]

  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :check_roles, :except => [ :index, :show ]

  # Displays statistics about an event
  def stats
    @event = Event.find_by_id(params[:id])
    @tickets_usage = gen_fname("tickets_usage")
    
    tott = Ticket.find(:all,:conditions => "event_id = #{@event.id}").length
    unbt = Ticket.find(:all,:conditions => "event_id = #{@event.id} and state = #{Ticket::UNBOOKED}").length
    unut = Ticket.find(:all,:conditions => "event_id = #{@event.id} and state = #{Ticket::NOT_USED}").length
    uset = Ticket.find(:all,:conditions => "event_id = #{@event.id} and (state = #{Ticket::USED} or state = #{Ticket::BOOKED} )").length

    g = Gruff::Pie.new(500)
    g.font = "/Library/Fonts/Arial.ttf"
    g.right_margin = 10
    g.left_margin = 10
    g.title_font_size = 30
    g.title = "Biljettanvändning för #{@event.name}"
    g.data  "Obokade biljetter", unbt
    g.data  "Oanvända biljetter", unut
    g.data  "Bokade/Använda biljetter" , uset
    g.write(@tickets_usage.to_s)
    @tickets_usage = @tickets_usage.sub("public","")

    if @event.questionaire
      @img_urls_o_q = []
      oi = 0

      @event.occasions.each do |o|
        @img_urls_o_q[oi] = []
        qi = 0
        
        @event.questionaire.questions.each do |q|
          @img_urls_o_q[oi][qi] = question_graph_path :occasion_id => o.id , :question_id => q.id
          qi += 1
        end
        oi += 1
      end
    end
  end

  # Displays the presentation page for an event
  def show
    @event = Event.find(params[:id])
    @category_groups = CategoryGroup.all :order => "name ASC"
  end

  def new
    @event = Event.new do |e|
      e.to_age = 19
      e.culture_provider_id = params[:culture_provider_id] if params[:culture_provider_id]

      if params[:culture_provider_id]
        culture_provider = CultureProvider.find params[:culture_provider_id]
        e.map_address = culture_provider.map_address
      end
    end  
    @category_groups = CategoryGroup.all :order => "name ASC"
    
    load_culture_providers()
  end

  def edit
    @event = Event.find(params[:id])
    @category_groups = CategoryGroup.all :order => "name ASC"

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
      params[:category_ids] ||= []
      @event.categories.clear

      params[:category_ids].each do |cid|
        begin
          @event.categories << Category.find(cid.to_i)
        rescue; end
      end

      flash[:notice] = 'Evenemanget skapades.'
      redirect_to(@event)
    else
      @category_groups = CategoryGroup.all :order => "name ASC"
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

      params[:category_ids] ||= []
      @event.categories.clear

      params[:category_ids].each do |cid|
        begin
          @event.categories << Category.find(cid.to_i)
        rescue; end
      end

      flash[:notice] = 'Evenemanget uppdaterades.'
      redirect_to(@event)
    else
      @category_groups = CategoryGroup.all :order => "name ASC"
      render :action => "new"
    end
  end

  def destroy
    @event = Event.find(params[:id])
    
    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @event
      return
    end

    @event.questionaire.destroy if @event.questionaire
    @event.destroy

    flash[:notice] = "Evenemanget raderades."
    redirect_to root_url()
  end

  def handle_links
    session[:event_link] ||= {}
    @culture_providers = CultureProvider.find :all, :order => "name ASC"
    @event = Event.find(params[:id])

    if session[:event_link][:selected_culture_provider] && session[:event_link][:selected_culture_provider] > 0
      @events = Event.find :all,
        :conditions => { :culture_provider_id => session[:event_link][:selected_culture_provider] },
        :order => "name ASC"
    end
  end

  def add_link
    session[:event_link][:selected_culture_provider] = params[:event_link][:culture_provider_id].to_i
    from = Event.find(params[:id])
    to = Event.find(params[:event_link][:event_id])
    from.linked_events << to
    to.linked_events << from

    flash[:notice] = "Evenemangslänken lades till."
    redirect_to handle_links_event_url(from)
  end

  def remove_link
    from = Event.find(params[:id])
    to = Event.find(params[:other_id])

    from.linked_events.delete(to)
    to.linked_events.delete(from)

    flash[:notice] = "Evenemangslänken togs bort."
    redirect_to handle_links_event_url(from)
  end

  
  def options_list
    conditions = {}
    conditions[:culture_provider_id] = params[:culture_provider_id] if params[:culture_provider_id]

    @events = Event.find :all, :conditions => conditions, :order => "name ASC"

    render :action => "options_list", :content_type => 'text/plain'
  rescue
    render :text => "", :content_type => 'text/plain', :status => 404
  end


  private

  # Loads the culture providers for the event creation sequence.
  # If the user is an admin, he/she can create events for all culture
  # provders, while culture workers only can create events for the
  # culture providers they are associated with.
  def load_culture_providers
    if current_user.has_role?(:admin)
      @culture_providers = CultureProvider.all :order => "name ASC"
    else
      @culture_providers = current_user.culture_providers.find :all, :order => "name ASC"
    end
  end

  # Makes sure the user has privileges for administrating culture providers.
  # For use in +before_filter+
  def check_roles
    unless current_user.has_role?(:admin) || current_user.has_role?(:culture_worker)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
    end
  end

  # Generates random filenames for the generated graphs
  def gen_fname(s)
    numpart = rand(10000)
    fname = "public/images/graphs/" + s + numpart.to_s + ".png"
    while File.exists?(fname) do
      numpart +=1
      fname = "public/images/graphs/" + s + numpart.to_s + ".png"
    end
    return fname
  end

end
