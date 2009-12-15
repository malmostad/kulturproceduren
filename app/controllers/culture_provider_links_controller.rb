# Controller for managing links to culture providers from events
# or other culture providers
class CultureProviderLinksController < ApplicationController
  layout "standard"

  before_filter :authenticate
  before_filter :require_admin

  def index
    @culture_provider = CultureProvider.find params[:culture_provider_id]
  end

  def new
    @culture_provider = CultureProvider.find params[:culture_provider_id]
    @culture_providers = CultureProvider.not_linked_to(@culture_provider).paginate :page => params[:page],
      :order => sort_order("name")
  end

  def select
    from = CultureProvider.find params[:culture_provider_id]
    to = CultureProvider.find params[:id]

    from.linked_culture_providers << to
    to.linked_culture_providers << from

    flash[:notice] = "Länken mellan arrangörerna skapades."

    redirect_to culture_provider_culture_provider_links_url(:culture_provider_id => from.id)
  end

  def destroy
    from = CultureProvider.find params[:culture_provider_id]
    to = CultureProvider.find params[:id]

    from.linked_culture_providers.delete(to)
    to.linked_culture_providers.delete(from)

    flash[:notice] = "Länken mellan arrangörerna togs bort."

    redirect_to culture_provider_culture_provider_links_url(:culture_provider_id => from.id)
  end

  protected

  def sort_column_from_param(p)
  "name"
  end
end
