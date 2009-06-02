class BookingController < ApplicationController
  require "pp"
  before_filter :authenticate
  layout "standard"

  def book
    @user = current_user

    @occasion = Occasion.find_by_id(params[:occasion_id])

    if ( @occasion.nil? )
      flash[:error] = "Ingen föreställning angiven"
      redirect_to :controller => "occasions"
      return
    end

    @groups = @user.groups
    @seats_available = Occasion.find(params[:occasion_id]).seats - Ticket.find(:all, :conditions => { :occasion_id => @occasion.id }).length

    if params[:what] == "book"
      # Utför bokning och omdirigera till visa bokningar
      group = Group.find(params[:group_id])

      if (group.nil?)
        flash[:error] = "Ingen grupp angiven"
        redirect_to :controller => "booking", :action => "book", :occasion_id => params[:occasion_id]
        return
      end

      if params[:no_tickets].nil? || params[:no_tickets].to_i < 0
        flash[:error] = "Du måte ange antal biljetter du vill boka"
        redirect_to :controller => "booking", :action => "book", :occasion_id => params[:occasion_id]
        return
      end

      case @occasion.event.ticket_state
      when Event::ALLOTED_GROUP
        tickets = Ticket.find(:all,
          :conditions => {
            :group_id => params[:group_id],
            :event_id => @occasion.event_id,
            :state => Ticket::UNBOOKED
          })
      when Event::ALLOTED_DISTRICT
        tickets = Ticket.find(:all,
          :conditions => {
            :district_id => group.school.district.id,
            :event_id => @occasion.event_id,
            :state => Ticket::UNBOOKED
          })
      when Event::FREE_FOR_ALL
        tickets = Ticket.find(:all,
          :conditions => {
            :event_id => @occasion.event_id,
            :state => Ticket::UNBOOKED
          })
      else
        flash[:error] = "Inte bokningsbart evenemang"
        redirect_to :controller => "event", :action => "show"
        return
      end

      if params[:no_tickets].to_i > tickets.length
        flash[:error] = "Du kan bara boka #{tickets.length} på den här föreställningen - valde du rätt grupp?"
        redirect_to :controller => "booking", :action => "book", :occasion_id => params[:occasion_id]
        return
      elsif @seats_available < params[:no_tickets].to_i
        flash[:error] = "Du kan inte boka #{params[:no_tickets]} - Det finns bara #{@seats_available} platser som är obokade på den här föreställningen "
        redirect_to :controller => "booking", :action => "book", :occasion_id => params[:occasion_id]
        return
      else
        # Borde detta göras mha sql-update pga prestandaskäl?
        ntick = 0
        while (ntick < params[:no_tickets].to_i ) do
          tickets[ntick].occasion_id = params[:occasion_id]
          tickets[ntick].state = Ticket::BOOKED
          tickets[ntick].save
          ntick += 1
        end
        redirect_to :controller => "booking", :action => "show"
        return
      end

    else
      ## Visa bokingsmöjligheter
      @overflow_warn = 0
      @bookable_tickets = {}

      @groups.each do |g|
        case @occasion.event.ticket_state
        when Event::ALLOTED_GROUP
          @bookable_tickets["#{g.id}"] = Ticket.find(:all,
            :conditions => {
              :group_id => g.id,
              :event_id => @occasion.event_id,
              :state => Ticket::UNBOOKED
            })
          
          @overflow_warn = 1 if @bookable_tickets["#{g.id}"].length > @seats_available
        when Event::ALLOTED_DISTRICT
          @bookable_tickets["#{g.id}"] = Ticket.find(:all,
            :conditions => {
              :district_id => group.school.district.id,
              :event_id => @occasion.event_id,
              :state => Ticket::UNBOOKED
            })
          
          @overflow_warn = 1 if @bookable_tickets["#{g.id}"].length > @seats_available
        when Event::FREE_FOR_ALL
          @bookable_tickets["#{g.id}"] = Ticket.find(:all,
            :conditions => {
              :event_id => @occasion.event_id,
              :state => Ticket::UNBOOKED
            })
          
          @overflow_warn = 1 if @bookable_tickets["#{g.id}"].length > @seats_available
        else
          flash[:error] = "Inte bokningsbart evenemang"
          redirect_to :controller => "event", :action => "show"
          return
        end
      end
    end
  end # method book

  def show
    @user = current_user
    @groups = @user.groups
    @occasions_by_group = {}

    @groups.each do |g|
      @occasions_by_group["#{g.id}"] = {}
      tickets = Ticket.find(:all, :conditions => [ "group_id = ? and occasion_id is not null", g.id ])
      tickets.each do |t|
        if @occasions_by_group["#{g.id}"]["#{t.occasion_id}"].nil? then
          @occasions_by_group["#{g.id}"]["#{t.occasion_id}"] = 1
        else
          @occasions_by_group["#{g.id}"]["#{t.occasion_id}"] += 1
        end
      end
    end
    
    pp @occasions_by_group
  end

  def unbook
    @user = current_user
    @occasion = Occasion.find_by_id(params[:occasion_id])
    
    if ( @occasion.nil? )
      flash[:error] = "Ingen föreställning angiven"
      redirect_to :controller => "occasions"
      return
    end

    @groups = @user.groups

    pp @groups
    pp params

    if params[:what] == "unbook" then

      # Utför bokning och omdirigera till visa bokningar

      group = Group.find_by_id(params[:group_id])

      if ( group.nil?)
        flash[:error] = "Ingen grupp angiven"
        redirect_to :controller => "booking", :action => "book", :occasion_id => params[:occasion_id]
        return
      end

      if ( ( params[:no_tickets].nil? ) or ( params[:no_tickets].to_i < 0 ) )
        flash[:error] = "Du måte ange antal biljetter du vill avboka"
        redirect_to :controller => "booking", :action => "book", :occasion_id => params[:occasion_id]
        return
      end

      tickets = Ticket.find(:all,
        :conditions => {
          :occasion_id => @occasion.id,
          :group_id => group.id,
          :state => Ticket::BOOKED
        })

      if params[:no_tickets].to_i > tickets.length
        flash[:error] = "Du kan bara avboka #{tickets.length}"
        redirect_to :controller => "booking", :action => "unbook", :occasion_id => params[:occasion_id]
        return
      else
        # Borde detta göras mha sql-update pga prestandaskäl?
        ntick = 0
        while (ntick < params[:no_tickets].to_i ) do
          tickets[ntick].occasion_id = nil
          tickets[ntick].state = Ticket::UNBOOKED
          tickets[ntick].save
          ntick += 1
        end
        redirect_to :controller => "booking", :action => "show"
        return
      end
    else
      ## Visa avbokingsmöjligheter
      @unbookable_tickets = {}
      
      @groups.each do |g|
        @unbookable_tickets["#{g.id}"] = Ticket.find(:all,
          :conditions => {
            :group_id => g.id,
            :occasion_id => @occasion.id,
            :state => Ticket::BOOKED
          })
      end
      
      pp @bookable_tickets
    end
  end
end

