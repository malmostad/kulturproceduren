class AllotmentController < ApplicationController

  layout "standard"
  
  def index
    @events = Event.find :all, :order => "name ASC"
  end

  def select_event
    session[:allotment] = {}
    session[:allotment][:event_id] = params["allotment"]["event_id"]
    session[:allotment][:num_tickets] = params["allotment"]["num_tickets"]

    redirect_to :action => "distribute"
  end

  def distribute
    unless session[:allotment][:event_id]
      flash[:error] = "Ett evenemang måste väljas innan fördelningen kan göras."
      redirect_to :action => "index"
      return
    end

    @event = Event.find session[:allotment][:event_id]
    @districts = District.find :all, :order => "name ASC"
  end

  def create_tickets
    render :text => "<pre>#{params.to_yaml}</pre>"
  end

end
