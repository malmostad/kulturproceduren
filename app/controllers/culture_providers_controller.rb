class CultureProvidersController < ApplicationController
  layout "standard"

  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :require_admin, :only => [ :new, :create, :destroy ]
  
  def index
    @culture_providers = CultureProvider.all
  end

  def show
    @culture_provider = CultureProvider.find(params[:id])
    @today = Date.today
  end

  def new
    @culture_provider = CultureProvider.new
    render :action => "edit"
  end

  def edit
    @culture_provider = CultureProvider.find(params[:id])

    unless current_user.can_administrate?(@culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @culture_provider
    end
  end

  def create
    @culture_provider = CultureProvider.new(params[:culture_provider])

    unless current_user.can_administrate?(@culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @culture_provider
      return
    end

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
      flash[:notice] = 'Arrangören uppdaterades'
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
end
