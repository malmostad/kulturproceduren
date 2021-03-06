class EventLinksController < ApplicationController
  layout "application"

  before_filter :authenticate
  before_filter :load_entity

  def index
    session[:event_links] ||= {}

    @culture_providers = CultureProvider.order "name"

    if session[:event_links][:selected_culture_provider]
      @selected_culture_provider = CultureProvider.find session[:event_links][:selected_culture_provider]

      @events = Event.where(culture_provider_id: @selected_culture_provider.id).order(sort_order("name"))
      if @culture_provider
        @events = @events.not_linked_to_culture_provider(@culture_provider)
      else
        @events = @events.not_linked_to_event(@event)
      end

      # @events = @events.paginate(page: params[:page])
    end
  end

  def select_culture_provider
    session[:event_links] ||= {}
    session[:event_links][:selected_culture_provider] = params[:selected_culture_provider_id].to_i

    if @culture_provider
      redirect_to culture_provider_event_links_url(@culture_provider)
    elsif @event
      redirect_to event_event_links_url(@event)
    end
  end

  def select_event
    new_link = Event.find params[:id]

    if @event
      @event.linked_events << new_link
      new_link.linked_events << @event
      flash[:notice] = "Länken mellan evenemangen skapades."
      redirect_to event_event_links_url(event_id: @event.id)
    elsif @culture_provider
      @culture_provider.linked_events << new_link
      flash[:notice] = "Länken mellan evenemanget och arrangören skapades."
      redirect_to culture_provider_event_links_url(@culture_provider)
    end
  end

  def destroy
    linked = Event.find params[:id]

    if @event
      @event.linked_events.delete(linked)
      linked.linked_events.delete(@event)
      flash[:notice] = "Länken mellan evenemangen togs bort."
      redirect_to event_event_links_url(event_id: @event.id)
    elsif @culture_provider
      @culture_provider.linked_events.delete(linked)
      flash[:notice] = "Länken mellan evenemanget och arrangören togs bort."
      redirect_to culture_provider_event_links_url(@culture_provider)
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
