# -*- encoding : utf-8 -*-
# Controller for managing notification requests
class NotificationRequestsController < ApplicationController
  layout "standard"

  before_filter :load_event
  before_filter :require_booker

  def new
    @notification_request = NotificationRequest.new
    @notification_request.event = @event

    case @event.ticket_state
    when :alloted_group, :alloted_district
      load_group_selection_collections()
      @notification_request.group_id = session[:group_selection][:group_id]
    when :free_for_all
      if NotificationRequest.unbooking_for(current_user, @event)
        flash[:warning] = "Du är redan registrerad för restplatser på detta evenemang"
        redirect_to(@event)
      end
    else
      flash[:warning] = "Evenemanget är inte bokningsbart."
      redirect_to(@event)
    end
  end

  def create
    if params[:cancel]
      redirect_to(@event)
      return
    end

    @notification_request = NotificationRequest.new(params[:notification_request]) do |req|
      req.event = @event
      req.user = current_user

      if @event.free_for_all?
        req.target_cd = NotificationRequest.targets.for_unbooking
      else
        req.target_cd = NotificationRequest.targets.for_transition
      end
    end

    @notification_request.save!

    if @event.free_for_all?
      flash[:notice] = "Du är nu registrerad att få meddelanden om restplatser på detta evenemang blir tillgängliga."
    else
      flash[:notice] = "Du är nu registrerad att få meddelanden när platser på detta evenemang blir tillgängliga för din klass/avdelning."
    end
    redirect_to @event
  end

  private

  # Makes sure the user has privileges to book tickets. For use in <tt>before_filter</tt>
  def require_booker
    unless current_user.can_book?
      flash[:error] = "Du har inte behörighet att boka platser"
      redirect_to root_url()
    end
  end

  # Loads the selected event
  def load_event
    @event = Event.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Kunde inte hitta angivet evenemang"
    redirect_to root_url()
  end

end
