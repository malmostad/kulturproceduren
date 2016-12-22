# Controller for doing the allotment of tickets to groups for a specific
# event
class AllotmentController < ApplicationController

  layout "application"

  before_filter :authenticate
  before_filter :require_admin
  before_filter :load_event

  cache_sweeper :event_sweeper, only: [ :create, :update, :destroy ]

  # Intializing view for the allotment process, displays a form
  # for allotment parameters
  def init
    if @event.school_types.blank?
      @districts = District.order("name ASC")
    else
      @districts = @event.school_type_districts
    end
  end

  # Stores the allotment parameters in the session and redirects
  # to the distribution view
  def assign_params

    incoming = params[:allotment]

    session[:allotment] = {}
    session[:allotment][:release_date] = Date.parse(incoming[:release_date])

    if incoming.has_key?(:school_transition_date) and not incoming[:school_transition_date].blank?
      session[:allotment][:school_transition_date] = Date.parse(incoming[:school_transition_date])
    end
    if incoming.has_key?(:district_transition_date) and not incoming[:district_transition_date].blank?
      skip_district_transition =
          incoming.has_key?(:skip_district_transition) and
          not incoming[:skip_district_transition].blank? and
          incoming[:skip_district_transition] == 'on'
      if not skip_district_transition then
        session[:allotment][:district_transition_date] = Date.parse(incoming[:district_transition_date])
      end
    end
    if incoming.has_key?(:free_for_all_transition_date) and not incoming[:free_for_all_transition_date].blank?
      session[:allotment][:free_for_all_transition_date] = Date.parse(incoming[:free_for_all_transition_date])
    end

    session[:allotment][:num_tickets] = incoming[:num_tickets].to_i
    session[:allotment][:ticket_state] = Event.new(ticket_state: incoming[:ticket_state].to_i).ticket_state

    session[:allotment][:bus_booking] = incoming[:bus_booking].to_i == 1
    if incoming.has_key?(:last_bus_booking_date) and not incoming[:last_bus_booking_date].blank?
      session[:allotment][:last_bus_booking_date] = Date.parse(incoming[:last_bus_booking_date])
    end

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

    unless incoming[:district_ids].blank?
      # Collect the selected districts ids and store them in the session
      ids = incoming[:district_ids].collect { |id| id.to_i }

      # -1 as an id means all ids
      if ids.include?(-1)
        session[:allotment][:district_ids] = nil
      else
        session[:allotment][:district_ids] ||= []
        session[:allotment][:district_ids] |= ids
      end
    end

    if session[:allotment][:ticket_state] == :free_for_all_with_excluded_districts
      if ids.include?(-1)
        session[:allotment][:excluded_district_ids] = []
      else
        session[:allotment][:excluded_district_ids] = District.all.pluck(:id) - ids
      end
      redirect_to action: "create_free_for_all_tickets", id: params[:id]
      return

    elsif session[:allotment][:ticket_state] == :free_for_all
      # If the selected ticket state is free for all,
      # then we don't need to do any distribution
      session[:allotment][:excluded_district_ids] = []
      redirect_to action: "create_free_for_all_tickets", id: params[:id]
      return

    elsif @event.allotments.empty?
      # Store the preliminary distribution in the session as the working distribution
      session[:allotment][:working_distribution] = get_preliminary_distribution(
        @event,
        session[:allotment][:district_ids],
        session[:allotment][:num_tickets],
        session[:allotment][:ticket_state])
    else
      # Store the existing distribution in the session as the working distribution
      session[:allotment][:working_distribution] = get_ticket_distribution(
        @event,
        load_working_districts(),
        session[:allotment][:extra_groups],
        session[:allotment][:ticket_state])
    end

    redirect_to action: "distribute", id: params[:id]
  end

  #Saves nessesary event information
  def save_event_information
    # Update the event
    @event.allotments.clear

    @event.last_transitioned_date = Date.today if @event.ticket_state != session[:allotment][:ticket_state]

    @event.ticket_release_date          = session[:allotment][:release_date]
    @event.school_transition_date       = session[:allotment][:school_transition_date]
    @event.district_transition_date     = session[:allotment][:district_transition_date]
    @event.free_for_all_transition_date = session[:allotment][:free_for_all_transition_date]
    @event.ticket_state                 = session[:allotment][:ticket_state]
    @event.bus_booking                  = session[:allotment][:bus_booking]
    @event.last_bus_booking_date        = session[:allotment][:last_bus_booking_date]

    if @event.free_for_all_with_excluded_districts?
      @event.excluded_district_ids = session[:allotment][:excluded_district_ids] || []
    else
      @event.excluded_district_ids = []
    end

    @event.save!
  end

  # Creates tickets that are in the free for all state
  def create_free_for_all_tickets
    save_event_information()

    @event.allotments.create!(
      user: current_user,
      amount: session[:allotment][:num_tickets],
      excluded_district_ids: @event.excluded_district_ids
    )

    session[:allotment] = nil
    flash[:notice] = "Biljetter till evenemanget har fördelats."
    redirect_to ticket_allotment_event_url(@event)
  end

  # Renders a view for distributing the tickets
  def distribute
    @districts = load_working_districts()

    if session[:allotment][:extra_groups]
      @extra_groups = Group.includes(:school).find session[:allotment][:extra_groups]
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
      save_event_information()

      tickets_created = 0

      if session[:allotment][:ticket_state] == :alloted_group
        # Assign the tickets to groups
        groups = Group.includes(school: :district).find assignment.keys

        groups.each do |group|
          amount = assignment[group.id]
          @event.allotments.create!(
            user: current_user,
            group: group,
            district: group.school.district,
            amount: amount,
            excluded_district_ids: []
          )
          tickets_created += amount

          logger.info "Moving #{group.id} last in priority"
          group.move_last_in_prio
        end

      elsif session[:allotment][:ticket_state] == :alloted_school
        # Assign the tickets to schools
        schools = School.includes(:district).find assignment.keys

        schools.each do |school|
          amount = assignment[school.id]
          @event.allotments.create!(
              user: current_user,
              school: school,
              district: school.district,
              amount: amount,
              excluded_district_ids: []
          )
          tickets_created += amount
        end

      elsif session[:allotment][:ticket_state] == :alloted_district
        # Assign the tickets to districts
        districts = District.find assignment.keys

        districts.each do |district|
          amount = assignment[district.id]
          @event.allotments.create!(
            user: current_user,
            district: district,
            amount: amount,
            excluded_district_ids: []
          )
          tickets_created += amount
        end
      end

      # Create extra tickets for tickets that have not been assigned to a specific
      # district or group
      extra_tickets = session[:allotment][:num_tickets] - tickets_created
      @event.allotments.create!(
        user: current_user,
        amount: extra_tickets,
        excluded_district_ids: []
      ) if extra_tickets > 0

      session[:allotment] = nil
      flash[:notice] = "Biljetter till evenemanget har fördelats."
      redirect_to ticket_allotment_event_url(@event)
    else
      session[:allotment][:extra_groups] ||= []
      session[:allotment][:extra_groups] << params[:add_group][:group_id].to_i
      session[:allotment][:extra_groups].uniq!

      session[:allotment][:working_distribution] = assignment

      redirect_to action: "distribute", id: params[:id]
    end
  end

  # Completely removes an allotment from an event
  def destroy
    @event.allotments.collect(&:destroy)

    session[:allotment] = nil

    @event.ticket_release_date = nil
    @event.school_transition_date = nil
    @event.district_transition_date = nil
    @event.free_for_all_transition_date = nil
    @event.ticket_state = 0
    @event.excluded_district_ids = []
    @event.save!

    flash[:notice] = "Fördelningen togs bort."
    redirect_to @event
  end


  private

  # Loads the working districts from the session
  def load_working_districts
    if session[:allotment][:district_ids]
      return District.order("name ASC").find(session[:allotment][:district_ids])
    elsif !@event.school_types.blank?
      return @event.school_type_districts
    else
      return District.order("name ASC")
    end
  end

  # Load the current event
  def load_event
    begin
      @event = Event.includes(:culture_provider).find params[:id]

      if @event.ticket_release_date && @event.ticket_release_date <= Date.today
        flash[:error] = "Fördelning kan inte göras efter ett evenemangs biljettsläpp."
        redirect_to @event
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Ett giltigt evenemang måste väljas för fördelning av biljetter."
      redirect_to controller: "events", action: "index"
    end
  end


  # Assign the children count to the districts, schools and groups.
  #
  # This method counts the number of children in the target age span
  # in the groups in the given districts, and then sums these amounts
  # in the parent school and district
  def assign_children(event, districts)
    district_ids = districts.map{|d| d.id}
    from_age = event.from_age
    to_age = event.to_age
    children_per_group_in_age_range = num_children_in_districts_for_ages(district_ids, from_age, to_age)
    tot_children_in_age_range = children_per_group_in_age_range.sum{|r| r[:quantity]}
    children_per_school_in_age_range = num_children_per_school_in_districts(district_ids)

    total_children = 0

    # Assign child count
    districts.each do |district|
      district.num_children = 0
      district.tot_children = 0

      district.distribution_schools = district.schools.find_by_age_span(event.from_age, event.to_age)
      district.distribution_schools.each do |school|
        school.num_children = 0
        school.tot_children = children_per_school_in_age_range.find{|r| r[:school_id] == school.id}[:quantity]
        district.tot_children += school.tot_children

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

  def num_children_in_districts_for_ages(district_ids, from_age, to_age)
    district_ids_string = district_ids.join(',')
    sql = <<-END
      select
        d.id as district_id,
        s.id as school_id,
        g.id as group_id,
        sum(ag.quantity) as quantity
      from age_groups ag
      join groups g on ag.group_id = g.id
      join schools s on g.school_id = s.id
      join districts d on s.district_id = d.id
      where ag.age between #{from_age} and #{to_age}
      and d.id in (#{district_ids_string})
      group by d.id, s.id, g.id
      order by d.id, s.id, g.id
    END

    puts "DEBUG_SQL: #{sql}"
    res = ActiveRecord::Base.connection.execute(sql)
    stats = res.collect.map{|r| {district_id: r[:district_id.to_s].to_i , school_id: r[:school_id.to_s].to_i, group_id: r[:group_id.to_s].to_i, quantity: r[:quantity.to_s].to_i}}
    return stats
  end

  def num_children_per_school_in_districts(district_ids)
    district_ids_string = district_ids.join(',')
    sql = <<-END
      select
        s.id as school_id,
        sum(ag.quantity) as quantity
      from age_groups ag
      join groups g on ag.group_id = g.id
      join schools s on g.school_id = s.id
      join districts d on s.district_id = d.id
      where d.id in (#{district_ids_string})
      group by s.id
      order by s.id
    END

    puts "DEBUG_SQL: #{sql}"
    res = ActiveRecord::Base.connection.execute(sql)
    stats = res.collect.map{|r| {school_id: r[:school_id.to_s].to_i, quantity: r[:quantity.to_s].to_i}}
    return stats
  end

  # Assigns the working distribution from the session
  #
  # This stores the number of allotted tickets directly in the group objects,
  # and the sum of allotted tickets is stored in the schools and districts
  def assign_working_distribution(event, districts, tickets, ticket_state)
    assign_children(event, districts)
    assigned_tickets = 0

    if ticket_state == :alloted_group
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

    elsif ticket_state == :alloted_school
      districts.each do |district|
        district.num_tickets = 0;
        district.distribution_schools.each do |school|
          school.num_tickets = 0;
          school.num_tickets += (session[:allotment][:working_distribution][school.id] || 0).to_i;
          district.num_tickets += school.num_tickets
          assigned_tickets += school.num_tickets
        end
      end

    elsif ticket_state == :alloted_district

      districts.each do |district|
        district.num_tickets = (session[:allotment][:working_distribution][district.id] || 0).to_i;
        assigned_tickets += district.num_tickets
      end

    end

    return tickets - assigned_tickets
  end


  # Creates a working distribution from the current ticket distribution on an event
  def get_ticket_distribution(event, districts, extra_group_ids, ticket_state)
    distribution = {}
    assign_children(event, districts)

    if ticket_state == :alloted_group
      group_counts = event.tickets.group("group_id").count

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

    elsif ticket_state == :alloted_school
      school_counts = event.tickets.group("school_id").count

      districts.each do |district|
        district.distribution_schools.each do |school|
          distribution[school.id] = school_counts[school.id].to_i;
        end
      end

    elsif ticket_state == :alloted_district
      district_counts = event.tickets.group("district_id").count
      districts.each { |d| distribution[d.id] = district_counts[d.id].to_i }
    end

    return distribution
  end

  # Creates a working distribution from a preliminary distribution based on
  # the number of tickets and the number of children in each district
  def get_preliminary_distribution(event, district_ids, tickets, ticket_state)
    distribution = {}

    total_query = AgeGroup.active.with_age(event.from_age, event.to_age)
    total_query = total_query.with_district(district_ids) unless district_ids.blank?
    children_per_district = total_query.num_children_per_district
    logger.info "\nChildren per district:#{children_per_district.to_yaml}"

    total_children = children_per_district.values.reduce(:+)
    total_tickets = tickets
    extra_pool = 0

    children_per_district.each_pair do |district_id, num_children|
      assigned_tickets = ((num_children.to_f / total_children.to_f) * total_tickets).floor + extra_pool

      logger.info "\n\n\nAssigning #{assigned_tickets} (#{extra_pool} from extra_pool) tickets for #{district_id} (#{num_children} children)"

      tickets -= assigned_tickets

      if ticket_state == :alloted_group
        children_per_group = AgeGroup.
          active.
          with_age(event.from_age, event.to_age).
          with_district(district_id).
          num_children_per_group

        logger.info "\n\nChildren per group in district #{district_id}:#{children_per_group.to_yaml}"

        sorted_ids = Group.sort_ids_by_priority(children_per_group.keys)
        sorted_ids.each do |group_id|
          amount = children_per_group[group_id.to_i] + 1
          logger.info "\nAmount for #{group_id}: #{amount}, tickets left: #{assigned_tickets}"
          if assigned_tickets >= amount
            assigned_tickets -= amount
            distribution[group_id.to_i] = amount
            logger.info "Giving #{amount} tickets to #{group_id}"
          end
        end

        logger.info "Pooling #{assigned_tickets} tickets"
        extra_pool = assigned_tickets

      elsif ticket_state == :alloted_school
        children_per_school = AgeGroup.
            active.
            with_age(event.from_age, event.to_age).
            with_district(district_id).
            num_children_per_school

        logger.info "\n\nChildren per school in district #{district_id}:#{children_per_school.to_yaml}"

        sorted_ids = children_per_school.keys.map{|x| x}.sort
        sorted_ids.each do |school_id|
          amount = children_per_school[school_id] + 1
          logger.info "\nAmount for #{school_id}: #{amount}, tickets left: #{assigned_tickets}"
          if assigned_tickets >= amount
            assigned_tickets -= amount
            distribution[school_id.to_i] = amount
            logger.info "Giving #{amount} tickets to school.id: #{school_id}"
          end
        end

        logger.info "Pooling #{assigned_tickets} tickets"
        extra_pool = assigned_tickets

      elsif ticket_state == :alloted_district
        distribution[district_id.to_i] = assigned_tickets
      end
    end

    Rails.logger.info("\nPreliminary distribution:\n#{distribution.to_yaml}\n")

    return distribution
  end

end
