class AllotmentController < ApplicationController

  layout "standard"
  
  def index
    @events = Event.without_tickets.find :all, :order => "name ASC"
    render :action => "index"
  end
  alias_method :new, :index

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
    assignment = params["allotment"]["ticket_assignment"].reject { |k,v| v.to_i <= 0 }

    event = Event.find session[:allotment][:event_id]
    groups = Group.find assignment.keys

    groups.each do |group|
      num = assignment[group.id.to_s].to_i

      1.upto(num) do
        ticket = Ticket.new do |t|
          t.group = group
          t.event = event
          t.state = Ticket::CREATED
        end

        ticket.save!
      end
    end

    flash[:notice] = "Biljetter till evenemanget har fördelats."
    redirect_to :action => "index"
  end

end
