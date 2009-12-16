# Controller for managing links to culture providers from events
# or other culture providers
class CultureProviderLinksController < ApplicationController
  layout "standard"

  before_filter :authenticate
  before_filter :load_culture_provider

  def index
  end

  def new
    @culture_providers = CultureProvider.not_linked_to(@culture_provider).paginate :page => params[:page],
      :order => sort_order("name")
  end

  def select
    to = CultureProvider.find params[:id]

    @culture_provider.linked_culture_providers << to
    to.linked_culture_providers << @culture_provider

    flash[:notice] = "Länken mellan arrangörerna skapades."

    redirect_to culture_provider_culture_provider_links_url(:culture_provider_id => @culture_provider.id)
  end

  def destroy
    to = CultureProvider.find params[:id]

    @culture_provider.linked_culture_providers.delete(to)
    to.linked_culture_providers.delete(@culture_provider)

    flash[:notice] = "Länken mellan arrangörerna togs bort."

    redirect_to culture_provider_culture_provider_links_url(:culture_provider_id => @culture_provider.id)
  end

  protected

  def load_culture_provider
    @culture_provider = CultureProvider.find params[:culture_provider_id]

    unless current_user.can_administrate?(@culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @culture_provider
    end
  end

  def sort_column_from_param(p)
    "name"
  end
end
