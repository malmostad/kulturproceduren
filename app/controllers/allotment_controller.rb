# Controller for doing the allotment of tickets to groups for a specific
# event
class AllotmentController < ApplicationController

  layout "standard"

  before_filter :authenticate
  before_filter :require_admin
  before_filter :load_event

  # Intializing view for the allotment process, displays a form
  # for allotment parameters
  def init
    @districts = District.all :order => "name ASC"
  end

  # Stores the allotment parameters in the session and redirects
  # to the distribution view
  def assign_params

    session[:allotment] = {}
    session[:allotment][:release_date] = Date.parse(params[:allotment][:release_date])
    session[:allotment][:num_tickets] = params[:allotment][:num_tickets].to_i
    session[:allotment][:ticket_state] = params[:allotment][:ticket_state].to_i

    unless @event.tickets.empty?
      # Add the number of tickets already assigned to an event
      session[:allotment][:num_tickets] += @event.tickets.size
      session[:allotment][:ticket_state] = @event.ticket_state

      # Load the districts from the event
      session[:allotment][:district_ids] ||= []
      session[:allotment][:district_ids] = @event.districts.collect { |d| d.id.to_i }

      # Load any extra groups from the event
      session[:allotment][:extra_groups] = @event.not_targeted_group_ids
    end

    unless params[:allotment][:district_ids].blank?
      # Collect the selected districts ids and store them in the session
      ids = params[:allotment][:district_ids].collect { |id| id.to_i }

      # -1 as an id means all ids
      if ids.include?(-1)
        session[:allotment][:district_ids] = nil
      else
        session[:allotment][:district_ids] ||= []
        session[:allotment][:district_ids] |= ids
      end
    end

    if session[:allotment][:ticket_state] == Event::FREE_FOR_ALL
      # If the selected ticket state is free for all, we don't need to do any
      # distribution
      redirect_to :action => "create_free_for_all_tickets", :id => params[:id]
      return
    elsif @event.tickets.empty?
      # Store the preliminary distribution in the session as the working distribution
      session[:allotment][:working_distribution] =
        get_preliminary_distribution(@event,
                                    load_working_districts(),
                                    session[:allotment][:num_tickets],
                                    session[:allotment][:ticket_state])
    else
      # Store the existing distribution in the session as the working distribution
      session[:allotment][:working_distribution] =
        get_ticket_distribution(@event,
                                load_working_districts(),
                                session[:allotment][:extra_groups],
                                session[:allotment][:ticket_state])
    end

    redirect_to :action => "distribute", :id => params[:id]
  end

  # Creates tickets that are in the free for all state
  def create_free_for_all_tickets
    @event.tickets.clear

    @event.ticket_release_date = session[:allotment][:release_date]
    @event.ticket_state = session[:allotment][:ticket_state]
    @event.save!

    1.upto(session[:allotment][:num_tickets]) do
      ticket = Ticket.new do |t|
        t.event = @event
        t.state = Ticket::UNBOOKED
      end

      ticket.save!
    end

    session[:allotment] = nil
    flash[:notice] = "Biljetter till evenemanget har fördelats."
    redirect_to @event
  end

  # Renders a view for distributing the tickets
  def distribute
    load_group_selection_collections()
    @districts = load_working_districts()

    if session[:allotment][:extra_groups]
      @extra_groups = Group.find session[:allotment][:extra_groups],
        :include => :school
    end

    @tickets_left = assign_working_distribution(@event,
                                                @districts,
                                                session[:allotment][:num_tickets],
                                                session[:allotment][:ticket_state])
  end

  # Creates tickets based on the current working distribution,
  # or adds an extra group to the working data depending on the incoming
  # submission
  def create_tickets
    assignment = {}
    params[:allotment][:ticket_assignment].each { |k,v| assignment[k.to_i] = v.to_i if v.to_i > 0 }

    if params[:create_tickets]
      # Update the event
      @event.tickets.clear

      @event.ticket_release_date = session[:allotment][:release_date]
      @event.ticket_state = session[:allotment][:ticket_state]
      @event.save!

      tickets_created = 0

      if session[:allotment][:ticket_state] == Event::ALLOTED_GROUP
        # Assign the tickets to groups
        groups = Group.find assignment.keys, :include => { :school => :district }
        schools = []

        groups.each do |group|
          num = assignment[group.id]

          1.upto(num) do
            ticket = Ticket.new do |t|
              t.group = group
              t.event = @event
              t.district = group.school.district
              t.state = Ticket::UNBOOKED
            end

            ticket.save!
            tickets_created += 1
          end

          schools << group.school unless schools.include?(group.school)
        end

        schools.each { |s| s.move_last_in_prio }
      elsif session[:allotment][:ticket_state] == Event::ALLOTED_DISTRICT
        # Assign the tickets to districts
        districts = District.find assignment.keys

        districts.each do |district|
          num = assignment[district.id]

          1.upto(num) do
            ticket = Ticket.new do |t|
              t.event = @event
              t.district = district
              t.state = Ticket::UNBOOKED
            end

            ticket.save!
            tickets_created += 1
          end
        end
      end

      # Create extra tickets for tickets that have not been assigned to a specific
      # district or group
      tickets_created.upto(session[:allotment][:num_tickets] - 1) do
        ticket = Ticket.new do |t|
          t.event = @event
          t.state = Ticket::UNBOOKED
        end

        ticket.save!
      end

      session[:allotment] = nil
      flash[:notice] = "Biljetter till evenemanget har fördelats."
      redirect_to @event
    else
      session[:allotment][:extra_groups] ||= []
      session[:allotment][:extra_groups] << params[:add_group][:group_id].to_i
      session[:allotment][:extra_groups].uniq!

      session[:allotment][:working_distribution] = assignment

      redirect_to :action => "distribute", :id => params[:id]
    end
  end


  # Completely removes an allotment from an event
  def destroy
    @event.tickets.clear

    session[:allotment] = nil

    @event.ticket_release_date = nil
    @event.ticket_state = 0
    @event.save!

    flash[:notice] = "Fördelningen togs bort."
    redirect_to @event
  end


  private

  # Loads the working districts from the session
  def load_working_districts
    if session[:allotment][:district_ids]
      return District.find(session[:allotment][:district_ids], :order => "name ASC")
    else
      return District.all(:order => "name ASC")
    end
  end

  # Load the current event
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


  # Assign the children count to the districts, schools and groups.
  #
  # This method counts the number of children in the target age span
  # in the groups in the given districts, and then sums these amounts
  # in the parent school and district
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

  # Assigns the working distribution from the session
  #
  # This stores the number of allotted tickets directly in the group objects,
  # and the sum of allotted tickets is stored in the schools and districts
  def assign_working_distribution(event, districts, tickets, ticket_state)
    assign_children(event, districts)
    assigned_tickets = 0

    if ticket_state == Event::ALLOTED_GROUP
      districts.each do |district|
        district.num_tickets = 0;
        district.distribution_schools.each do |school|
          school.num_tickets = 0;
          school.distribution_groups.each do |group|
            group.num_tickets = (session[:allotment][:working_distribution][group.id] || 0).to_i;
            school.num_tickets += group.num_tickets
            district.num_tickets += group.num_tickets
            assigned_tickets += group.num_tickets
          end
        end
      end

      if @extra_groups
        @extra_groups.each do |group|
          group.num_tickets = (session[:allotment][:working_distribution][group.id] || 0).to_i;
          assigned_tickets += group.num_tickets
        end
      end

    elsif ticket_state == Event::ALLOTED_DISTRICT

      districts.each do |district|
        district.num_tickets = 
          (session[:allotment][:working_distribution][district.id] || 0).to_i;
        assigned_tickets += district.num_tickets
      end

    end

    return tickets - assigned_tickets
  end


  # Creates a working distribution from the current ticket distribution on an event
  def get_ticket_distribution(event, districts, extra_group_ids, ticket_state)
    distribution = {}
    assign_children(event, districts)


    if ticket_state == Event::ALLOTED_GROUP
      group_counts = event.tickets.count(:group => "group_id")

      districts.each do |district|
        district.distribution_schools.each do |school|
          school.distribution_groups.each do |group|
            distribution[group.id] = group_counts[group.id].to_i;
          end
        end
      end

      if extra_group_ids
        extra_group_ids.each do |id|
          distribution[id] = group_counts[id].to_i;
        end
      end

    elsif ticket_state == Event::ALLOTED_DISTRICT
      district_counts = event.tickets.count(:group => "district_id")
      districts.each { |d| distribution[d.id] = district_counts[d.id].to_i }
    end

    return distribution
  end

  # Creates a working distribution from a preliminary distribution based on
  # the number of tickets and the number of children in each district
  def get_preliminary_distribution(event, districts, tickets, ticket_state)
    distribution = {}

    total_children = assign_children(event, districts)

    districts.each do |district|
      assigned_tickets = ((district.num_children.to_f / total_children.to_f) * tickets).floor

      tickets -= assigned_tickets

      if ticket_state == Event::ALLOTED_GROUP
        district.distribution_schools.each do |school|
          school.distribution_groups.each do |group|
            if assigned_tickets > group.num_children + 1
              assigned_tickets -= group.num_children + 1
              distribution[group.id] = group.num_children + 1
            end
          end
        end

        tickets += assigned_tickets
      elsif ticket_state == Event::ALLOTED_DISTRICT
        distribution[district.id] = assigned_tickets
      end
    end

    return distribution
  end

end
