# Controller for managing links to culture providers from events
# or other culture providers
class CultureProviderLinksController < ApplicationController
  layout "application"

  before_filter :authenticate
  before_filter :load_entity

  def index
    if @culture_provider
      @culture_providers = CultureProvider.not_linked_to_culture_provider(@culture_provider)
        .order(sort_order("name"))
    elsif @event
      @culture_providers = CultureProvider.not_linked_to_event(@event)
        .order(sort_order("name"))
    end
  end

  def select
    new_link = CultureProvider.find params[:id]

    if @culture_provider
      @culture_provider.linked_culture_providers << new_link
      new_link.linked_culture_providers << @culture_provider

      flash[:notice] = "Länken mellan arrangörerna skapades."
      redirect_to culture_provider_culture_provider_links_url(culture_provider_id: @culture_provider.id)
    elsif @event
      @event.linked_culture_providers << new_link
      flash[:notice] = "Länken mellan arrangören och evenemanget skapades."
      redirect_to event_culture_provider_links_url(event_id: @event.id)
    end
  end

  def destroy
    linked = CultureProvider.find params[:id]

    if @culture_provider
      @culture_provider.linked_culture_providers.delete(linked)
      linked.linked_culture_providers.delete(@culture_provider)

      flash[:notice] = "Länken mellan arrangörerna togs bort."

      redirect_to culture_provider_culture_provider_links_url(culture_provider_id: @culture_provider.id)
    elsif @event
      @event.linked_culture_providers.delete(linked)
      flash[:notice] = "Länken mellan arrangören och evenemanget togs bort."
      redirect_to event_culture_provider_links_url(event_id: @event.id)
    end
  end

  protected

  def load_entity
    if !params[:culture_provider_id].blank?
      @culture_provider = CultureProvider.find params[:culture_provider_id]

      unless current_user.can_administrate?(@culture_provider)
        flash[:error] = "Du har inte behörighet att komma åt sidan."
        redirect_to @culture_provider
      end
    elsif !params[:event_id].blank?
      @event = Event.includes(:culture_provider).find params[:event_id]

      unless current_user.can_administrate?(@event.culture_provider)
        flash[:error] = "Du har inte behörighet att komma åt sidan."
        redirect_to @event
      end
    end
  end

  def sort_column_from_param(p)
    "name"
  end
end
