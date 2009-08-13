class NotificationRequestsController < ApplicationController
  layout "standard"
  before_filter :check_occasion , :only => [ :new , :create , :get_input_area ]
  before_filter :check_user , :only => [ :new , :create , :get_input_area ]

  def check_user
    @user = current_user
    if not @user.can_book?
      flash[:error] = "Du har inte behörighet att boka biljetter"
      redirect_to "/"
      return
    end
    if @user.email.blank? or @user.cellphone.blank?
      flash[:notice] = "Du måste ange mobiltelefon nummer och e-mail adress för att kunna få information om kommande föreställningar"
      redirect_to @user
    end
  end

  def check_occasion
    if params[:occasion_id].blank? and not params[:notification_request]["occasion_id"].blank?
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
      return
    end
  end

  def get_input_area
    @notification_request = NotificationRequest.new
    @notification_request.user = @user
    if params[:group_id].blank? or params[:group_id].to_i == 0
      render :text => "Otacksamma unge!"
      return
    end
    @notification_request.group = Group.find(params[:group_id])
    @notification_request.occasion = @occasion
    render :partial => "input_area", :content_type => "text/plain"
  end

  # GET /notification_requests
  # GET /notification_requests.xml
  def index
    @notification_requests = NotificationRequest.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @notification_requests }
    end
  end

  # GET /notification_requests/1
  # GET /notification_requests/1.xml
  def show
    @notification_request = NotificationRequest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @notification_request }
    end
  end

  # GET /notification_requests/new
  # GET /notification_requests/new.xml
  def new
    @notification_request = NotificationRequest.new
    @notification_request.occasion = @occasion
    @notification_request.user = @user
  end

  # GET /notification_requests/1/edit
  def edit
    @notification_request = NotificationRequest.find(params[:id])
  end

  
  # POST /notification_requests
  # POST /notification_requests.xml
  def create
    if params[:commit] == "Skapa förfrågan"
      @notification_request = NotificationRequest.new(params[:notification_request])
      if @notification_request.save
        flash[:notice] = "Du kommer att få medelande när det finns fler biljetter att boka"
        redirect_to "/"
      else
        flash[:error] = "Kunde inte spara ..."
        redirect_to "/"
      end
    elsif params[:commit] == "Börja om"
      redirect_to :action => "new" , :occasion_id => @occasion.id
      return
    else
      @notification_request = NotificationRequest.new
      @notification_request.occasion = @occasion
      @notification_request.user = @user
      if not params[:district_id].blank? or params[:district_id].to_i == 0
        @schools = School.find(:all , :conditions => { :district_id => params[:district_id] } )
      end
      if not ( params[:school_id].blank? or params[:school_id].to_i == 0 )
        @groups = Group.find(:all , :conditions => {:school_id => params[:school_id] } )
      end
      if not ( params[:group_id].blank? or params[:group_id].to_i == 0)
        @notification_request.group = Group.find(params[:group_id])
      end
      render :new
    end
  end

  # PUT /notification_requests/1
  # PUT /notification_requests/1.xml
  def update
    @notification_request = NotificationRequest.find(params[:id])

    respond_to do |format|
      if @notification_request.update_attributes(params[:notification_request])
        flash[:notice] = 'NotificationRequest was successfully updated.'
        format.html { redirect_to(@notification_request) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @notification_request.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_requests/1
  # DELETE /notification_requests/1.xml
  def destroy
    @notification_request = NotificationRequest.find(params[:id])
    @notification_request.destroy

    respond_to do |format|
      format.html { redirect_to(notification_requests_url) }
      format.xml  { head :ok }
    end
  end
end
