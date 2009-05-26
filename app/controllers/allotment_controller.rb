class AllotmentController < ApplicationController

  layout "standard"
  
  def index
    @events = Event.without_tickets.find :all, :order => "name ASC"
    @districts = District.all :order => "name ASC"
    render :action => "index"
  end
  alias_method :new, :index

  def select_event
    session[:allotment] = {}
    session[:allotment][:event_id] = params["allotment"]["event_id"]
    session[:allotment][:num_tickets] = params["allotment"]["num_tickets"]
    
    if params["allotment"]["district_ids"] && params["allotment"]["district_ids"].length > 0
      ids = params["allotment"]["district_ids"].collect { |id| id.to_i }

      unless ids.include?(-1)
        session[:allotment][:district_ids] = ids
      end
    end

    redirect_to :action => "distribute"
  end

  def distribute


    unless session[:allotment][:event_id]
      flash[:error] = "Ett evenemang måste väljas innan fördelningen kan göras."
      redirect_to :action => "index"
      return
    end

    @event = Event.find session[:allotment][:event_id]

    if session[:allotment][:district_ids]
      @districts = District.find session[:allotment][:district_ids], :order => "name ASC"
    else
      @districts = District.all :order => "name ASC"
    end
    

    @tickets_left = assign_distribution(@event, @districts, session[:allotment][:num_tickets].to_i)
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


  private

  def assign_distribution(event, districts, tickets)

    total_children = 0

    # Assign child count
    districts.each do |district|
      district.num_children = 0

      district.distribution_schools = district.schools.find_by_age_span(event.from_age, event.to_age)
      district.distribution_schools.each do |school|
        school.num_children = 0

        school.distribution_groups = school.groups.find_by_age_span(event.from_age, event.to_age)
        school.distribution_groups.each do |group|
          nc = group.age_groups.num_children_by_age_span event.from_age, event.to_age

          total_children += nc
          district.num_children += nc
          school.num_children += nc
          group.num_children = nc
        end
      end
    end

    # Assign tickets
    districts.each do |district|
      assigned_tickets = ((district.num_children.to_f / total_children.to_f) * tickets).floor

      puts "#{district.name}: #{assigned_tickets} (#{district.num_children} / #{total_children} = (#{district.num_children.to_f / total_children.to_f})) * #{tickets}"
      
      tickets -= assigned_tickets

      district.num_tickets = 0

      district.distribution_schools.each do |school|
        school.num_tickets = 0
        
        school.distribution_groups.each do |group|
          if assigned_tickets > group.num_children
            assigned_tickets -= group.num_children
            
            group.num_tickets = group.num_children
            school.num_tickets += group.num_tickets
            district.num_tickets += group.num_tickets
          else
            group.num_tickets = 0
          end
        end
      end

      tickets += assigned_tickets
    end

    return tickets
  end

end
