# Controller for managing culture providers
class CultureProvidersController < ApplicationController
  layout "standard"

  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :require_admin, :only => [ :new, :create, :destroy, :activate, :deactivate ]

  cache_sweeper :calendar_sweeper, :only => [ :create, :update, :destroy, :activate, :deactivate ]
  cache_sweeper :culture_provider_sweeper, :only => [ :create, :update, :destroy, :activate, :deactivate ]
  

  # Displays a paginated list of all culture providers
  def index
    if user_online? && current_user.has_role?(:admin)
      @culture_providers = CultureProvider.paginate :page => params[:page],
        :order => sort_order("name")
    else
      @culture_providers = CultureProvider.paginate :page => params[:page],
        :conditions => { :active => true },
        :order => sort_order("name")
    end
  end

  # Displays a culture provider's presentation page
  def show
    @culture_provider = CultureProvider.find params[:id], :include => [ :main_image ]
    @category_groups = CategoryGroup.all :order => "name ASC"
  end

  # Displays a form for adding a culture provider
  def new
    @culture_provider = CultureProvider.new
    render :action => "edit"
  end

  # Displays a form for editing an existing culture provider
  def edit
    @culture_provider = CultureProvider.find(params[:id])

    unless current_user.can_administrate?(@culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @culture_provider
    end
  end

  def create
    @culture_provider = CultureProvider.new(params[:culture_provider])

    if @culture_provider.save
      flash[:notice] = 'Arrangören skapades.'
      redirect_to(@culture_provider)
    else
      render :action => "edit"
    end
  end

  def update
    @culture_provider = CultureProvider.find(params[:id])

    if @culture_provider.update_attributes(params[:culture_provider])
      flash[:notice] = 'Arrangören uppdaterades.'
      redirect_to(@culture_provider)
    else
      render :action => "edit"
    end
  end

  def destroy
    @culture_provider = CultureProvider.find(params[:id])
    @culture_provider.destroy

    redirect_to(culture_providers_url)
  end

  def activate
    set_active(true)
  end

  def deactivate
    set_active(false)
  end


  protected

  # Always sort by the culture provider's name
  def sort_column_from_param(p)
    case p.to_sym
    when :active then "active"
    else
      "name"
    end
  end

  # Cache key for the list of upcoming occasions
  def upcoming_occasions_cache_key(culture_provider)
    "culture_providers/show/#{culture_provider.id}/upcoming_occasions/#{user_online? && current_user.can_book? ? "" : "not_" }bookable"
  end
  helper_method :upcoming_occasions_cache_key

  # Cache key for the list of standing events
  def standing_events_cache_key(culture_provider)
    "culture_providers/show/#{culture_provider.id}/standing_events"
  end
  helper_method :standing_events_cache_key


  private

  def set_active(active)
    culture_provider = CultureProvider.find(params[:id])
    culture_provider.active = active

    if culture_provider.save
      flash[:notice] = "Arrangören #{active ? "" : "de"}aktiverades."
    else
      flash[:error] = "Ett fel uppstod när arrangören skulle #{active ? "" : "de"}aktiveras. Var god försök igen senare."
    end

    redirect_to culture_provider
  end
end
