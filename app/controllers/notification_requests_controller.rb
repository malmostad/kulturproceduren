# Controller for managing notification requests
class NotificationRequestsController < ApplicationController
  layout "standard"

  before_filter :load_occasion
  before_filter :require_booker

  def new
    load_group_selection_collections()
    @notification_request = NotificationRequest.new
    @notification_request.occasion = @occasion
    @notification_request.group_id = session[:group_selection][:group_id]
  end

  def create
    @notification_request = NotificationRequest.new(params[:notification_request])
    @notification_request.occasion = @occasion
    @notification_request.user = current_user

    @notification_request.save!
    flash[:notice] = "Du är nu registrerad att få meddelanden när platser på detta evenemang blir tillgängliga för din grupp."
    redirect_to @occasion.event
  end

  private

  # Makes sure the user has privileges to book tickets. For use in +before_filter+
  def require_booker
    user = current_user
    unless user.can_book?
      flash[:error] = "Du har inte behörighet att boka platser"
      redirect_to root_url()
      return
    end

    if user.email.blank? or user.cellphone.blank?
      flash[:warning] = "Du måste ange mobiltelefonnummer och epostadress för att kunna få information om kommande föreställningar"
      redirect_to user
    end
  end

  # Loads the selected occasion
  def load_occasion
    @occasion = Occasion.find(params[:occasion_id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Kunde inte hitta angiven föreställning"
    redirect_to root_url()
  end

end
