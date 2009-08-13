class NotificationRequestsController < ApplicationController
  layout "standard"

  before_filter :check_occasion
  before_filter :check_user

  def get_input_area
    @notification_request = NotificationRequest.new
    @notification_request.user = @user

    if params[:group_id].blank? || params[:group_id].to_i <= 0
      render :text => ""
      return
    end

    @notification_request.group = Group.find(params[:group_id])
    @notification_request.occasion = @occasion

    render :partial => "input_area", :content_type => "text/plain"
  end

  def new
    @notification_request = NotificationRequest.new
    @notification_request.occasion = @occasion
  end

  def create
    if params[:commit] == "Registrera"
      @notification_request = NotificationRequest.new(params[:notification_request])
      @notification_request.occasion = @occasion
      @notification_request.user = current_user

      @notification_request.save!
      flash[:notice] = "Du är nu registrerad att få meddelanden när biljetter för detta evenemang blir tillgängliga för din grupp."
      redirect_to @occasion.event

    elsif params[:commit] == "Börja om"
      redirect_to new_occasion_notification_request_url(@occasion)
    else
      @notification_request = NotificationRequest.new
      @notification_request.occasion = @occasion

      if not params[:district_id].blank? or params[:district_id].to_i <= 0
        @schools = School.find(:all, :conditions => { :district_id => params[:district_id] } )
      end

      if not ( params[:school_id].blank? or params[:school_id].to_i <= 0 )
        @groups = Group.find(:all, :conditions => {:school_id => params[:school_id] } )
      end

      if not ( params[:group_id].blank? or params[:group_id].to_i <= 0)
        @notification_request.group = Group.find(params[:group_id])
      end

      render :new
    end
  end

  private

  def check_user
    @user = current_user
    unless @user.can_book?
      flash[:error] = "Du har inte behörighet att boka biljetter"
      redirect_to "/"
      return
    end

    if @user.email.blank? or @user.cellphone.blank?
      flash[:warning] = "Du måste ange mobiltelefonnummer och epostadress för att kunna få information om kommande föreställningar"
      redirect_to @user
    end
  end

  def check_occasion
    if params[:occasion_id].blank? && !params[:notification_request]["occasion_id"].blank?
      params[:occasion_id] = params[:notification_request]["occasion_id"]
    end

    if params[:occasion_id].blank? or params[:occasion_id].to_i == 0
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end
    
    begin
      @occasion = Occasion.find(params[:occasion_id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Kunde inte hitta angiven föreställning"
      redirect_to "/"
    end
  end

end
