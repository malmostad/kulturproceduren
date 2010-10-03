# Controller for managing occasions
class OccasionsController < ApplicationController

  layout "standard"
  
  require "pdf/writer"
  require "pdf/simpletable"

  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :require_culture_worker, :only => [ :edit, :update, :destroy, :cancel ]
  before_filter :require_host, :only => [ :report_show , :report_create ]

  cache_sweeper :calendar_sweeper, :only => [ :create, :update, :destroy, :cancel ]
  cache_sweeper :culture_provider_sweeper, :only => [ :create, :update, :destroy, :cancel ]
  cache_sweeper :event_sweeper, :only => [ :create, :update, :destroy, :cancel ]


  # Displays a form for reporting the attendance on an occasion
  def report_show

    if params[:id].blank? || params[:id].to_i == 0
      flash[:error] = "Ingen föreställning angiven"
      redirect_to root_url()
      return
    end

    begin
      @occasion = Occasion.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Kunde inte hitta angiven föreställning"
      redirect_to root_url()
      return
    end

    if @occasion.date >= Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to root_url()
      return
    end

    @groups = @occasion.attending_groups

    render :report

  end

  # Creates an attendace report from the form parameters
  def report_create
    if params[:id].blank? || params[:id].to_i == 0
      flash[:error] = "Ingen föreställning angiven"
      redirect_to root_url()
      return
    end

    begin
      @occasion = Occasion.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Kunde inte hitta angiven föreställning"
      redirect_to root_url()
      return
    end

    if @occasion.date >= Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to root_url()
      return
    end

    @groups = @occasion.attending_groups

    @groups.each do |group|
      attendance = {}
      params[:attendance][group.id.to_s].each do |k,v|
        attendance[k.to_sym] = v.to_i unless v.blank?
      end

      tickets = Ticket.find_not_unbooked(group, @occasion)

      tickets.each do |ticket|
        if ticket.adult
          if attendance.has_key?(:adult)
            ticket.state = attendance[:adult] > 0 ? Ticket::USED : Ticket::NOT_USED
            attendance[:adult] -= 1
          else
            ticket.state = Ticket::BOOKED
          end
        elsif ticket.wheelchair
          if attendance.has_key?(:wheelchair)
            ticket.state = attendance[:wheelchair] > 0 ? Ticket::USED : Ticket::NOT_USED
            attendance[:wheelchair] -= 1
          else
            ticket.state = Ticket::BOOKED
          end
        else
          if attendance.has_key?(:normal)
            ticket.state = attendance[:normal] > 0 ? Ticket::USED : Ticket::NOT_USED
            attendance[:normal] -= 1
          else
            ticket.state = Ticket::BOOKED
          end
        end

        ticket.save!
      end

      # Create extra tickets for extra attendants
      [ :adult, :wheelchair, :normal ].each do |type|
        if attendance.has_key?(type) && attendance[type] > 0
          create_extra_tickets(attendance[type], tickets[0], type) 
        end
      end
    end

    flash[:notice] = "Närvaron uppdaterades."
    redirect_to report_show_occasion_url(@occasion)
  end


  # Displays a specific occasion as the part of an event presentation
  def show
    @selected_occasion = Occasion.find(params[:id])
    @event = @selected_occasion.event
    @category_groups = CategoryGroup.all :order => "name ASC"

    render :template => "events/show"
  end

  # Displays an editing form in place of the new occasion form in the
  # event presentation
  def edit
    @event = @occasion.event
    @category_groups = CategoryGroup.all :order => "name ASC"
    render :template => "events/show"
  end

  def create
    @occasion = Occasion.new(params[:occasion])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
      return
    end

    if @occasion.save
      session[:last_occasion_added] = params[:occasion]
      flash[:notice] = 'Föreställningen skapades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      @category_groups = CategoryGroup.all :order => "name ASC"
      render :template => "events/show"
    end
  end

  def update
    if @occasion.update_attributes(params[:occasion])
      flash[:notice] = 'Föreställningen uppdaterades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      @category_groups = CategoryGroup.all :order => "name ASC"
      render :template => "events/show"
    end
  end

  def destroy
    @occasion.destroy

    flash[:notice] = 'Föreställningen togs bort.'
    redirect_to(@occasion.event)
  end

  def cancel
    @occasion.cancelled = true
    @occasion.save!

    OccasionMailer.deliver_occasion_cancelled_email(@occasion)

    flash[:notice] = "Föreställningen ställdes in."
    redirect_to(@occasion)
  end


  # Displays the ticket availability on the occasion's event. For use in an Ajax request.
  def ticket_availability
    @occasion = Occasion.find(params[:id], :include => { :event => :culture_provider })
    wrong_state = false

    case @occasion.event.ticket_state
    when Event::ALLOTED_GROUP
      @entities = School.find_with_tickets_to_event(@occasion.event)
    when Event::ALLOTED_DISTRICT
      @entities = @occasion.event.districts.find :all, :order => "districts.name ASC"
    when Event::FREE_FOR_ALL
      nil
    else
      wrong_state = true
    end

    if request.xhr? && wrong_state
      render :text => "", :content_type => "text/plain", :status => 404
    elsif request.xhr?
      render :partial => "ticket_availability_list", :content_type => "text/plain", :layout => false
    elsif wrong_state
      flash[:error] = "Platstillgänglighet kan inte presenteras för den önskade föreställningen."
      redirect_to root_url()
    end
  end


  private

  # Creates extra tickets for unannounced attendants when reporting attendance
  def create_extra_tickets(attendance, base, type)
    1.upto(attendance) do |i|
      ticket = Ticket.new do |t|
        t.state = Ticket::USED
        t.group = base.group
        t.event = base.event
        t.occasion = base.occasion
        t.district = base.district
        t.companion = base.companion
        t.user = current_user
        t.adult = (type == :adult)
        t.wheelchair = (type == :wheelchair)
        t.booked_when = DateTime.now
      end

      ticket.save!
    end
  end

  # Checks if the user is a host. For use in <tt>before_filter</tt>.
  def require_host
    @user = current_user

    unless @user.has_role?(:host) || @user.has_role?(:admin)
      flash[:error] = "Du har inte behörighet att rapportera närvaro"
      redirect_to root_url()
      return
    end
  end

  # Checks if the user has administration privileges on the occasion.
  # For use in <tt>before_filter</tt>.
  def require_culture_worker
    @occasion = Occasion.find(params[:id])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
    end
  end
end
