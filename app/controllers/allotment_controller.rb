class AllotmentController < ApplicationController

  layout "standard"

  before_filter :authenticate
  before_filter :require_admin
  before_filter :load_event

  def init
    @districts = District.all :order => "name ASC"
  end

  def assign_params
    session[:allotment] = {}
    session[:allotment][:release_date] = Date.parse(params[:allotment][:release_date])
    session[:allotment][:num_tickets] = params[:allotment][:num_tickets].to_i

    unless @event.tickets.empty?
      session[:allotment][:district_ids] ||= []
      session[:allotment][:district_ids] = @event.districts.collect { |d| d.id.to_i }

      session[:allotment][:extra_groups] = @event.not_targeted_group_ids
    end

    unless params[:allotment][:district_ids].blank?
      ids = params[:allotment][:district_ids].collect { |id| id.to_i }

      if ids.include?(-1)
        session[:allotment][:district_ids] = nil
      else
        session[:allotment][:district_ids] ||= []
        session[:allotment][:district_ids] |= ids
      end
    end

    redirect_to :action => "distribute", :id => params[:id]
  end

  def distribute
    if session[:allotment][:district_ids]
      @districts = District.find session[:allotment][:district_ids], :order => "name ASC"
    else
      @districts = District.all :order => "name ASC"
    end

    if session[:allotment][:extra_groups]
      @extra_groups = Group.find session[:allotment][:extra_groups],
        :include => :school
    end

    if session[:allotment][:working_distribution]
      @tickets_left = assign_working_distribution(@event, @districts, session[:allotment][:num_tickets])
    elsif @event.tickets.empty?
      @tickets_left = assign_preliminary_distribution(@event, @districts, session[:allotment][:num_tickets])
    else
      assign_distribution_from_tickets(@event, @districts)
      @tickets_left = session[:allotment][:num_tickets]
    end

  end

  def create_tickets

    assignment = params[:allotment][:ticket_assignment].reject { |k,v| v.to_i <= 0 }

    if params[:create_tickets]
      @event.tickets.clear

      @event.ticket_release_date = session[:allotment][:release_date]
      @event.save!

      groups = Group.find assignment.keys, :include => { :school => :district }
      schools = []

      groups.each do |group|
        num = assignment[group.id.to_s].to_i

        1.upto(num) do
          ticket = Ticket.new do |t|
            t.group = group
            t.event = @event
            t.district = group.school.district
            t.state = Ticket::UNBOOKED
          end

          ticket.save!
        end

        schools << group.school unless schools.include?(group.school)
      end

      schools.each { |s| s.move_last_in_prio }

      session[:allotment] = nil
      flash[:notice] = "Biljetter till evenemanget har fördelats."
      redirect_to @event
    elsif params[:add_group_submit]
      session[:allotment][:extra_groups] ||= []
      session[:allotment][:extra_groups] << params[:add_group][:group_id].to_i
      session[:allotment][:extra_groups].uniq!

      session[:allotment][:working_distribution] = assignment

      redirect_to :action => "distribute", :id => params[:id]
    end
  end


  private

  def load_event
    begin
      @event = Event.find params[:id], :include => :culture_provider

      if @event.ticket_release_date && @event.ticket_release_date <= Date.today
        flash[:error] = "Fördelning kan inte göras efter ett evenemangs biljettsläpp."
        redirect_to @event
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Ett giltigt evenemang måste väljas för fördelning av biljetter."
      redirect_to :controller => "events", :action => "index"
    end
  end


  def assign_children(event, districts)
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

    return total_children
  end

  def assign_working_distribution(event, districts, tickets)
    assign_children(event, districts)
    assigned_tickets = 0
    
    districts.each do |district|
      district.num_tickets = 0;
      district.distribution_schools.each do |school|
        school.num_tickets = 0;
        school.distribution_groups.each do |group|
          group.num_tickets = (session[:allotment][:working_distribution][group.id.to_s] || 0).to_i;
          school.num_tickets += group.num_tickets
          district.num_tickets += group.num_tickets
          assigned_tickets += group.num_tickets
        end
      end
    end

    if @extra_groups
      @extra_groups.each do |group|
        group.num_tickets = (session[:allotment][:working_distribution][group.id.to_s] || 0).to_i;
        assigned_tickets += group.num_tickets
      end
    end

    return tickets - assigned_tickets
  end

  def assign_distribution_from_tickets(event, districts)
    assign_children(event, districts)

    group_counts = event.tickets.count(:group => "group_id")

    districts.each do |district|
      district.num_tickets = 0;
      district.distribution_schools.each do |school|
        school.num_tickets = 0;
        school.distribution_groups.each do |group|
          group.num_tickets = group_counts[group.id].to_i;
          school.num_tickets += group.num_tickets
          district.num_tickets += group.num_tickets
        end
      end
    end

    if @extra_groups
      @extra_groups.each do |group|
        group.num_tickets = group_counts[group.id].to_i;
      end
    end
  end

  def assign_preliminary_distribution(event, districts, tickets)

    # Assign children
    total_children = assign_children(event, districts)
    
    # Assign tickets
    districts.each do |district|
      assigned_tickets = ((district.num_children.to_f / total_children.to_f) * tickets).floor

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
