# Controller for managing events
class EventsController < ApplicationController
  layout "standard", :except => [ :options_list ]

  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :check_roles, :except => [ :index, :show ]

  cache_sweeper :calendar_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :culture_provider_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :event_sweeper, :only => [ :create, :update, :destroy ]


  # Displays the presentation page for an event
  def show
    @event = Event.find(params[:id])
    @category_groups = CategoryGroup.all :order => "name ASC"
  end

  # Displays the ticket allotment for an event
  def ticket_allotment
    @event = Event.find(params[:id])

    case @event.ticket_state
    when Event::ALLOTED_GROUP
      @ticket_count = @event.ticket_count_by_group
    when Event::ALLOTED_DISTRICT
      @ticket_count = @event.ticket_count_by_district
    when Event::FREE_FOR_ALL
      @ticket_count = nil
    else
      flash[:error] = "Evenemanget har ingen aktiv fördelning."
      redirect_to @event
    end
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

  # Renders a list of <tt>option</tt>-tags of events. For use in Ajax calls.
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
      @culture_providers = current_user.culture_providers.find :all,
        :conditions => { :active => true },
        :order => "name ASC"
    end
  end

  # Makes sure the user has privileges for administrating culture providers.
  # For use in <tt>before_filter</tt>
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
