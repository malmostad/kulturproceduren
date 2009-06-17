class BookingController < ApplicationController
  require "pp"
  
  before_filter :authenticate
  before_filter :check_booker
  
  layout "standard"

  def get_input_area
    @group = Group.find(params[:group_id])
    @occasion = Occasion.find(params[:occasion_id])
    render :partial => "input_area" , :locals => { :group => @group , :occasion => @occasion }
  end

  def book

    @user = current_user

    if params[:occasion_id].nil? || params[:occasion_id].to_i == 0
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end

    @occasion = Occasion.find(params[:occasion_id].to_i)

    if @occasion.nil?
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end

    if params[:commit] == "Hämta skolor" && !params[:district_id].nil? && params[:district_id].to_i != 0
      @schools = School.find :all , :conditions => { :district_id => params[:district_id] }
    elsif params[:commit] == "Hämta grupper"
      if not params[:district_id].nil? && params[:district_id].to_i != 0 && !params[:school_id].nil? && params[:school_id].to_i != 0
        @schools = School.find :all , :conditions => { :district_id => params[:district_id] }
        @groups  = Group.find :all , :conditions => { :school_id => params[:school_id] }
      else
        bork
      end
    elsif params[:commit] == "Välj grupp"
      if not params[:district_id].nil? && params[:district_id].to_i != 0 && !params[:school_id].nil? && params[:school_id].to_i != 0 && !params[:group_id].nil? && params[:group_id].to_i != 0
        @schools = School.find :all , :conditions => { :district_id => params[:district_id] }
        @groups  = Group.find :all , :conditions => { :school_id => params[:school_id] }
        @curgroup = Group.find(params[:group_id])
      else
        bork
      end
    elsif params[:commit] == "Boka"

      #"commit"=>"Boka", "seats_adult"=>"1", "district_id"=>"1", "group_id"=>"1", 
      #"seats_wheelchair"=>"1", "companion_telnr"=>"+46-31-868788", 
      #"occasion_id"=>"1", "comanpion_name"=>"Ove Jobring", 
      #"seats_students"=>"12", "companion_email"=>"ove.jobring@mgmt.gu.se", 
      #"booking_request"=>"Jag behöver en bogserbåt!", "school_id"=>"1"}

      curgroup = Group.find(params[:group_id]) or bork
      puts "curgroup = #{curgroup.id}"
      puts "DEGUBB: #{curgroup.ntickets_by_occasion(@occasion).to_i}"
      puts "DEGUBB2: #{( params[:seats_students].to_i + params[:seats_adult].to_i + params[:seats_wheelchair].to_i )}"
      
      if curgroup.ntickets_by_occasion(@occasion).to_i < ( params[:seats_students].to_i + params[:seats_adult].to_i + params[:seats_wheelchair].to_i )
        flash[:error] = "Du har bara #{curgroup.ntickets_by_occasion(@occasion)} platser du kan boka på den här föreställningen"
        bork
      elsif @occasion.wheelchair_seats < params[:seats_wheelchair].to_i
        flash[:error] = "Det finns bara #{@occasion.available_wheelchair_seats} rullstolsplatser du kan boka på den här föreställningen"
        bork
      elsif params[:companion_email].nil? || params[:companion_name].nil? || params[:companion_telnr].nil?
        flash[:error] = "Du måste fylla i alla fälten för medföljande vuxen"
        bork
      else
        #Do booking

        companion = Companion.new
        companion.tel_nr = params[:companion_telnr]
        companion.email = params[:companion_email]
        companion.name  = params[:companion_name]
        
        unless companion.save
          flash[:error] = "Kunde inte spara värdena för medföljande vuxen ... Försök igen?"
          bork
        end

        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        tempid = ""
        (1..45).each { |i| tempid << chars[rand(chars.size-1)] }

        puts "DEBUG: genererat ansformid = #{tempid}"
        
        ansform = AnswerForm.new
        ansform.id = tempid
        ansform.completed = false
        ansform.companion = companion
        ansform.occasion = @occasion
        ansform.group = curgroup
        ansform.questionaire = @occasion.event.questionaire
        ansform.save or bork

        unless params[:booking_request].blank?
          br = BookingRequirement.new
          br.occasion = @occasion
          br.group = curgroup
          br.requirement = params[:booking_request]
          br.save or bork
        end


        tot_requested = params[:seats_students].to_i + params[:seats_adult].to_i + params[:seats_wheelchair].to_i
        transaction_ok = true
        begin
          Ticket.transaction do
            tickets = curgroup.bookable_tickets(@occasion,true)
            if tickets.length < tot_requested
              flash[:error] = "Du försöker boka fler biljetter än vad som är tilldelat för gruppen på den här föreställningen."
              bork
            end

            ntickets = 0
            nadult = 0
            nwheelchair = 0

            while ntickets < tot_requested

              tickets[ntickets].state = Ticket::BOOKED
              tickets[ntickets].group = curgroup
              tickets[ntickets].companion = companion
              tickets[ntickets].user = @user
              tickets[ntickets].occasion = @occasion
              tickets[ntickets].wheelchair = false
              tickets[ntickets].adult = false
              tickets[ntickets].booked_when = DateTime.now

              if nadult < params[:seats_adult].to_i
                tickets[ntickets].adult = true
                nadult += 1
              elsif nwheelchair < params[:seats_wheelchair].to_i
                tickets[ntickets].wheelchair = true
                nwheelchair += 1
              end

              pp tickets[ntickets]

              unless tickets[ntickets].save
                transaction_ok = false
                raise ActiveRecord::Rollback
              end
              ntickets +=1
            end
          end
        rescue Exception
        end
        
        if transaction_ok
          flash[:notice] = "Du har bokat #{tot_requested} platser"
          redirect_to :controller => "booking" , :action => "show"
        else
          flash[:error] = "Kunde inte boka biljetterna ... Försök igen?"
          bork
        end
      end
    elsif !params[:commit].nil?
      # unrecognized commit parameter - generate error
      flash[:error] = "Och vad ville du egentligen göra nu????"
      bork
    end
    ## no params[:commit] - fall through and render default initial screen...
  end # method book

  def bork
    
    flash[:notice] = "Felaktiga parametrar"

    #
    #TODO : skicka med alla not nil? parametrar i redirecten.....
    #
    
    redirect_to :controller => "booking" , :action => "book" , :occasion_id => params[:occasion_id]
  end

  def show
    @user = current_user
  end

  def unbook
    @user = current_user
    @occasion = Occasion.find_by_id(params[:occasion_id])
    
    if @occasion.nil?
      flash[:error] = "Ingen föreställning angiven"
      redirect_to :controller => "occasions"
      return
    end

    @groups = []

    pp @groups
    pp params

    if params[:what] == "unbook" then

      # Utför bokning och omdirigera till visa bokningar

      group = Group.find_by_id(params[:group_id])

      if group.nil?
        flash[:error] = "Ingen grupp angiven"
        redirect_to :controller => "booking", :action => "book", :occasion_id => params[:occasion_id]
        return
      end

      if params[:no_tickets].nil? || params[:no_tickets].to_i < 0
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


  private

  def check_booker
    unless current_user.can_book?
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to "/"
    end
  end
end

