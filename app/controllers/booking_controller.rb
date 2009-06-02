class BookingController < ApplicationController
  require "pp"
  before_filter :authenticate
  layout "standard"

  def get_schools
    if params[:district_id].nil?
      flash[:error] = "Felaktiga parametrar"
      redirect_to :controller => "booking" , :action => "book"
      return
    else
      @schools = School.find :all , :conditions => { :district_id => params[:district_id] }
      render :partial => "schools_select"
    end
  end

  def get_groups
    if not params[:occasion_id].nil?
      @occasion = Occasion.find(params[:occasion_id])
    end
    if params[:school_id].nil?
      flash[:error] = "Felaktiga parametrar"
      redirect_to :controller => "booking" , :action => "book"
      return
    else
      @groups = Group.find :all , :conditions => { :school_id => params[:school_id] }
      render :partial => "groups_select"
    end
  end

  def get_input_area
    render :partial => "input_area"
  end

  def book
    @user = current_user

    @occasion = Occasion.find(params[:occasion_id])

    if ( @occasion.nil? )
      flash[:error] = "Ingen föreställning angiven"
      redirect_to :controller => "occasions"
      return
    end
    puts "#{params[:commit] == "Hämta skolor"}"
    puts "#{params[:district_id].nil?}"
    puts "#{params[:district_id].to_i}"
    if params[:commit] == "Hämta skolor" and not params[:district_id].nil? and params[:district_id].to_i != 0
      @schools = School.find :all , :conditions => { :district_id => params[:district_id] }
    elsif params[:commit] == "Hämta grupper"and not params[:district_id].nil? and params[:district_id].to_i != 0 and not params[:school_id].nil? and params[:school_id].to_i != 0
      @schools = School.find :all , :conditions => { :district_id => params[:district_id] }
      @groups  = Group.find :all , :conditions => { :school_id => params[:school_id] }
    else
      if params[:commit].nil?

      else
        flash[:notice] = "Felaktiga parametrar"
        redirect_to :controller => "booking" , :action => "book" , :occasion_id => params[:occasion_id]
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

