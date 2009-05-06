class NotificationRequestsController < ApplicationController
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

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @notification_request }
    end
  end

  # GET /notification_requests/1/edit
  def edit
    @notification_request = NotificationRequest.find(params[:id])
  end

  # POST /notification_requests
  # POST /notification_requests.xml
  def create
    @notification_request = NotificationRequest.new(params[:notification_request])

    respond_to do |format|
      if @notification_request.save
        flash[:notice] = 'NotificationRequest was successfully created.'
        format.html { redirect_to(@notification_request) }
        format.xml  { render :xml => @notification_request, :status => :created, :location => @notification_request }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @notification_request.errors, :status => :unprocessable_entity }
      end
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
