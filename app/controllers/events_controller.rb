# Controller for managing events
class EventsController < ApplicationController
  layout "application", except: [ :options_list ]

  before_filter :authenticate, except: :show
  before_filter :check_roles, except: :show

  cache_sweeper :calendar_sweeper, only: [ :create, :update, :destroy ]
  cache_sweeper :culture_provider_sweeper, only: [ :create, :update, :destroy ]
  cache_sweeper :event_sweeper, only: [ :create, :update, :destroy ]


  # Displays the presentation page for an event
  def show
    @event = Event.find(params[:id])
    @category_groups = CategoryGroup.order "name ASC"
  end

  # Displays the ticket allotment for an event
  def ticket_allotment
    @event = Event.find(params[:id])

    if @event.allotments.empty?
      flash[:error] = "Evenemanget har ingen aktiv fördelning."
      redirect_to @event
    end

    if params[:format] == "xls"
      send_csv(
        "fordelning_evenemang#{@event.id}.tsv",
        ticket_allotment_csv(@event)
      )
    end
  end

  def new
    @event = Event.new do |e|
      e.to_age = 19
      e.culture_provider_id = params[:culture_provider_id] if params[:culture_provider_id]
      e.is_age_range_used = false

      if params[:culture_provider_id]
        culture_provider = CultureProvider.find params[:culture_provider_id]
        e.map_address = culture_provider.map_address
      end
    end

    @category_groups = CategoryGroup.order(name: :asc)
    @school_types = SchoolType.order(name: :asc)
    
    load_culture_providers()
  end

  def edit
    @event = Event.find(params[:id])
    @category_groups = CategoryGroup.order(name: :asc)
    @school_types = SchoolType.order(name: :asc)

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @event
      return
    end

    render action: "new"
  end

  def create
    category_ids = params[:category_ids] || []
    @event = Event.new(params[:event])

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to root_url()
      return
    end

    if params[:is_age_range_used] && params[:is_age_range_used] == 'false' then
      @event.is_age_range_used = false
    end

    if @event.save
      @event.categories.clear

      category_ids.each do |category_id|
        begin
          @event.categories << Category.find(category_id.to_i)
        rescue; end
      end

      flash[:notice] = 'Evenemanget skapades.'
      redirect_to(@event)
    else
      load_culture_providers()
      @category_groups = CategoryGroup.order("name ASC")
      @school_types = SchoolType.order("name ASC")
      render action: "new"
    end
  end

  def update
    @event = Event.find(params[:id])

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @event
      return
    end

    category_ids = params[:category_ids] || []

    if @event.update_attributes(params[:event])

      @event.categories.clear

      category_ids.each do |cid|
        begin
          @event.categories << Category.find(cid.to_i)
        rescue; end
      end

      flash[:notice] = 'Evenemanget uppdaterades.'
      redirect_to(@event)
    else
      @category_groups = CategoryGroup.order("name ASC")
      @school_types = SchoolType.order("name ASC")
      render action: "new"
    end
  end

  def destroy
    @event = Event.find(params[:id])
    
    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @event
      return
    end

    @event.questionnaire.destroy if @event.questionnaire
    @event.destroy

    flash[:notice] = "Evenemanget raderades."
    redirect_to root_url()
  end

  # Renders a list of <tt>option</tt>-tags of events. For use in Ajax calls.
  def options_list
    @events = Event.order(name: :asc)
    @events = @events.where(culture_provider_id: params[:culture_provider_id]) if params[:culture_provider_id]
    render action: "options_list", content_type: 'text/plain'
  rescue
    render text: "", content_type: 'text/plain', status: 404
  end


  def transition
    @event = Event.find(params[:id])

    if Rails.env.production?
      redirect_to @event
    elsif @event.allotments.empty?
      flash[:error] = "Evenemanget har ingen aktiv fördelning."
      redirect_to @event
    end
  end
  def next_transition
    @event = Event.find(params[:id])

    if Rails.env.production?
      redirect_to @event
      return
    elsif @event.ticket_release_date > Date.today
      @event.ticket_release_date = Date.today
      @event.save!
      flash[:notice] = "Biljetterna släpptes. Evenemanget är nu bokningsbart."
    elsif @event.alloted_group?
      @event.district_transition_date = Date.today
      @event.transition_to_district!
      flash[:notice] = "Biljetterna är nu fördelade till området."
    elsif @event.alloted_district?
      @event.free_for_all_transition_date = Date.today
      @event.transition_to_free_for_all!
      flash[:notice] = "Biljetterna är nu fria att boka för alla."
    end

    redirect_to @event
  end


  private

  # Loads the culture providers for the event creation sequence.
  # If the user is an admin, he/she can create events for all culture
  # provders, while culture workers only can create events for the
  # culture providers they are associated with.
  def load_culture_providers
    if current_user.has_role?(:admin)
      @culture_providers = CultureProvider.order "name ASC"
    else
      @culture_providers = current_user.culture_providers.where(active: true).order("name ASC")
    end
  end

  # Makes sure the user has privileges for administrating culture providers.
  # For use in <tt>before_filter</tt>
  def check_roles
    unless current_user.has_role?(:admin) || current_user.has_role?(:culture_worker)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to root_url()
    end
  end

  def ticket_allotment_csv(event)
    CSV.generate(col_sep: "\t") do |csv|
      csv << [ "Område", "Skola", "Grupp", "Antal biljetter" ]

      event.allotments.each do |allotment|
        if allotment.for_group?
          row = [ allotment.district.name, allotment.group.school.name, allotment.group.name, allotment.amount ]
        elsif allotment.for_school?
          row = [ allotment.district.name, allotment.school.name, '', allotment.amount ]
        elsif allotment.for_district?
          row = [ allotment.district.name, '', '', allotment.amount ]
        else
          row = [ 'Hela staden', '', '', allotment.amount ]
        end

        csv << row
      end

    end
  end
end
