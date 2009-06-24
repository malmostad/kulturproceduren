class BookingController < ApplicationController
  require "pp"
  
  before_filter :authenticate
  before_filter :check_booker
  
  layout "standard"

  def load_vars
    begin
      @group = Group.find(params[:group_id])
      @occasion = Occasion.find(params[:occasion_id])
      t = Ticket.find(
        :first ,
        :select => "distinct companion_id" ,
        :conditions => {
          :group_id => @group.id ,
          :occasion_id => @occasion.id
        }
      )
    rescue ActiveRecord::RecordNotFound
      puts "Det blev bajs"
      flash[:error] = "Kunde inte hitta .... hem?"
    end
    unless t.blank? || t.companion_id == 0
      @companion = Companion.find(t.companion_id)
    end
    @nticks = Ticket.count(
      :all,
      :conditions => {
        :group_id => @group.id,
        :occasion_id=>@occasion.id ,
        :state=>Ticket::BOOKED,
        :wheelchair => false ,
        :adult=>false
      }
    )
    @naticks = Ticket.count(
      :all,
      :conditions => {
        :group_id => @group.id,
        :occasion_id=>@occasion.id ,
        :state=>Ticket::BOOKED,
        :wheelchair => false ,
        :adult=>true
      }
    )
    @nwticks = Ticket.count(
      :all,
      :conditions => {
        :group_id => @group.id,
        :occasion_id=>@occasion.id ,
        :state=>Ticket::BOOKED,
        :wheelchair => true ,
        :adult=>false
      }
    )
    @br = BookingRequirement.find(
      :first ,
      :conditions => {
        :group_id => @group.id ,
        :occasion_id => @occasion.id
      }
    )
    
    if Ticket.count(:all , :conditions => { :group_id => @group.id , :event_id => @occasion.event.id , :state => Ticket::BOOKED }) > 0
      @edit = true
    else
      @edit = false
    end
  end

  def get_input_area
    @group = Group.find(params[:group_id])
    @occasion = Occasion.find(params[:occasion_id])
    load_vars
    render :partial => "input_area" , :locals => {
      :group => @group ,
      :occasion => @occasion ,
      :companion => @companion ,
      :nticks => @nticks ,
      :naticks => @naticks ,
      :nwticks => @nwticks ,
      :br => @br ,
      :edit => @edit
    }
  end

  def book

    @user = current_user

    if params[:occasion_id].nil? || params[:occasion_id].to_i == 0
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end
    pp params
    
    @occasion = Occasion.find(params[:occasion_id].to_i)

    if @occasion.nil?
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end

    #    if ( not params[:group_id].blank? ) && @curgroup = Group.find(params[:group_id])
    #      params[:commit] = "Välj grupp"
    #      params[:district_id] = @curgroup.school.district.id
    #      params[:school_id] = @curgroup.school.id
    #    end

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
        @curgroup = Group.find(params[:group_id].to_i)
        if Ticket.count(:all , :conditions => { :group_id => @curgroup.id , :event_id => @occasion.event.id , :state => Ticket::BOOKED }) > 0
          flash[:info] = "Gruppen #{@curgroup.name} #{@curgroup.school.name} har redan bookat biljetter på den här evenemanget."
          @edit = true
          load_vars()
        end
      else
        #ej gilitiga paramuttrar.
        redirect_to "/"
        return
      end
    elsif params[:commit] == "Boka"
      puts "Do booking inside method book"
      @schools = School.find :all , :conditions => { :district_id => params[:district_id] }
      @groups  = Group.find :all , :conditions => { :school_id => params[:school_id] }
      @curgroup = Group.find(params[:group_id])
      params[:commit] = "Välj grupp"
      load_vars
      if Ticket.count(:all , :conditions => { :group_id => @curgroup.id , :event_id => @occasion.event.id , :state => Ticket::BOOKED }) > 0
        flash[:error] = "Gruppen #{@curgroup.name} #{@curgroup.school.name} har redan bookat biljetter på den här evenemanget."
        redirect_to "/"
        return
      end

      #"commit"=>"Boka", "seats_adult"=>"1", "district_id"=>"1", "group_id"=>"1",
      #"seats_wheelchair"=>"1", "companion_telnr"=>"+46-31-868788", 
      #"occasion_id"=>"1", "comanpion_name"=>"Ove Jobring", 
      #"seats_students"=>"12", "companion_email"=>"ove.jobring@mgmt.gu.se", 
      #"booking_request"=>"Jag behöver en bogserbåt!", "school_id"=>"1"}

      puts "curgroup = #{@curgroup.id}"
      puts "DEGUBB: #{@curgroup.ntickets_by_occasion(@occasion).to_i}"
      puts "DEGUBB2: #{( params[:seats_students].to_i + params[:seats_adult].to_i + params[:seats_wheelchair].to_i )}"

      #check_ntick sets flash-error message

      if not check_nticks(params[:seats_students],params[:seats_adult],params[:seats_wheelchair])
        render :book
        return
      else
        #Do booking


        @companion = Companion.new
        @companion.tel_nr = params[:companion_telnr]
        @companion.email = params[:companion_email]
        @companion.name  = params[:companion_name]
        
        unless @companion.save
          flash[:error] = "Kunde inte spara värdena för medföljande vuxen ... Försök igen?"
          render :book
          return
        end

        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        tempid = ""
        (1..45).each { |i| tempid << chars[rand(chars.size-1)] }

        puts "DEBUG: genererat ansformid = #{tempid}"
        
        ansform = AnswerForm.new
        ansform.id = tempid
        ansform.completed = false
        ansform.companion = @companion
        ansform.occasion = @occasion
        ansform.group = @curgroup
        ansform.questionaire = @occasion.event.questionaire
        unless ansform.save
          flash[:error] = "Kunde inte skapa utvärderingsformulär"
        end

        unless params[:booking_request].blank?
          br = BookingRequirement.new
          br.occasion = @occasion
          br.group = @curgroup
          br.requirement = params[:booking_request]
          unless br.save
            flash[:error] = "Kunde inte spara information ang extra behov!"
          end
        end
        tot_requested = params[:seats_students].to_i + params[:seats_adult].to_i + params[:seats_wheelchair].to_i
        if book_ticks(params[:seats_students].to_i,params[:seats_adult].to_i,params[:seats_wheelchair].to_i)
          flash[:notice] = "Du har bokat #{tot_requested} platser"
          redirect_to :controller => "booking" , :action => "show"
        else
          flash[:error] = "Kunde inte boka biljetterna ... Försök igen?"
          render :book
          return
        end
      end
    elsif params[:commit] == "Börja om"
      pp params
    elsif params[:commit] == "Ändra bokning"
      puts "Ändra bokning"
      if not check_nticks(params[:seats_students].to_i,params[:seats_adult].to_i,params[:seats_wheelchair].to_i)
        render :book
        return
      else
        #      {"commit"=>"Ändra bokning",   #   "companion_name"=>"1",    #  "seats_adult"=>"1", # "authenticity_token"=>"c5nxGL7lDEtT7O5B7PHA+U1Kadpv7H+M4Gb53WLwYkI=",
        #        "action"=>"book", #        "companion_telnr"=>"1",  #        "seats_wheelchair"=>"1", #        "group_id"=>"2", #        "district_id"=>"1",
        #        "controller"=>"booking", #        "occasion_id"=>"1", #        "booking_request"=>"1",#        "companion_email"=>"1",#        "seats_students"=>"2",
        #        "school_id"=>"1"}
        load_vars
        if ( not @companion.blank? or @companion.name != params[:companion_name] or @companion.email != params[:companion_email] or @companion.tel_nr != params[:companion_telnr]  )
          @companion.name = params[:companion_name]
          @companion.email = params[:companion_email]
          @companion.tel_nr = params[:companion_telnr]
          @companion.save or flash[:error] += "<br/> Kunde inte spara information ang medföljande vuxen"
        end
        if not params[:booking_request].blank?
          begin
            br = BookingRequirement.find(:conditions => {:occasion_id => @occasion.id , :group_id => @group.id})
          rescue ActiveRecord::RecordNotFound
            puts "bokning utan br ..."
          end
          if not br.blank?
            br.requirement=params[:booking_request]
            br.save or flash[:error] += "<br/> Kunde inte uppdatera information ang extra behov."
          end
        end
        if params[:seats_students].to_i != nticks || params[:seats_adult] != naticks || params[:seats_wheelchair] != nwticks
          Ticket.transaction do
            if unbok_all_ticks() && book_ticks(params[:seats_students],params[:seats_adult],params[:seats_wheelchair])
              flash[:info] += "<br/> Antalet bokade biljetter uppdaterade"
            else
              flash[:error] += "<br/> Kunde inte förändra antalet bokade biljetter"
              raise ActiveRecord::Rollback
            end
          end #transaction
        end
      end #check_nticks
    elsif !params[:commit].nil?
      # unrecognized commit parameter - generate error
      flash[:error] = "Och vad ville du egentligen göra nu????"
      bork
    end
    ## no params[:commit] - fall through and render default initial screen...
  end # method book

  def unbook_all_ticks
    trans_ok = true
    if @occasion.blank? or @group.blank?
      return false
    end
    begin
      Ticket.transaction do
        tickets = Ticket.find(:all,
          :conditions => {
            :occasion_id => @occasion.id,
            :group_id => @group.id,
            :state => Ticket::BOOKED
          })
        tickets.each do |t|
          t.state = Ticket::UNBOOKED
          t.occasion = nil
          t.companion = nil
          t.adult = false
          t.wheelchair = false
          t.booked_when = nil
          t.save or trans_ok = false
        end
        if not trans_ok
          raise ActiveRecord::Rollback
        end
      end
    rescue Exception
    end
    return trans_ok
  end

  def book_ticks(nreq_ticks , nreq_aticks , nreq_wticks )
    if not check_nticks(nreq_ticks.to_i , nreq_aticks.to_i , nreq_wticks.to_i )
      return false
    end
    tot_requested = nreq_ticks.to_i + nreq_aticks.to_i + nreq_wticks.to_i
    transaction_ok = true
    begin
      Ticket.transaction do
        #Dubbelkoll inne i transaktionen
        tickets = @group.bookable_tickets(@occasion,true)
        puts "==============================================================="
        puts "Bookable tickets = "
        pp tickets
        
        if tickets.length < tot_requested
          flash[:error] = "Du försöker boka fler biljetter än vad som är tilldelat för gruppen på den här föreställningen."
          render :book
          return
        end

        booked_tickets = 0
        booked_adult_tickets = 0
        booked_wheelchair_tickets = 0

        puts "booked_tickets = #{booked_tickets}"
        puts "tot_requested = #{tot_requested}"

        while booked_tickets < tot_requested
          puts "Försöker boka biljett"
          puts "Group = "
          pp @group
          puts "companion = "
          pp @companion
          puts "user="
          pp @user
          puts "Occasion = "
          pp @occasion
          puts "now = #{DateTime.now}"
          
          pp tickets[booked_tickets]
          puts "Uppdaterar"
          tickets[booked_tickets].state = Ticket::BOOKED
          tickets[booked_tickets].group = @group
          tickets[booked_tickets].companion = @companion
          tickets[booked_tickets].user = @user
          tickets[booked_tickets].occasion = @occasion
          tickets[booked_tickets].wheelchair = false
          tickets[booked_tickets].adult = false
          tickets[booked_tickets].booked_when = DateTime.now
          puts "Uppdatering klar - kollar a och w"
          pp tickets[booked_tickets]
          puts "Snoppen"
          puts "booked_adult_tickets=#{booked_adult_tickets}"
          puts "nreq_aticks = #{nreq_aticks}"
          puts "nreq_wticks = #{nreq_wticks}"
          
          if booked_adult_tickets.to_i < nreq_aticks.to_i
            tickets[booked_tickets].adult = true
            booked_adult_tickets += 1
          elsif booked_wheelchair_tickets.to_i < nreq_wticks.to_i
            tickets[booked_tickets].wheelchair = true
            booked_wheelchair_tickets += 1
          end

          puts "korv"
          puts "Försöker boka biljett 2"

          pp tickets[booked_tickets]
          retval = tickets[booked_tickets].save
          puts "Försökte spara biljetten och det gick = #{retval}"
          unless retval
            transaction_ok = false
            puts "Biljett-bajs ...."
            raise ActiveRecord::Rollback
          end
          booked_tickets +=1
          puts "Klar med en blijett"
        end
      end

    end
    puts "boka biljetter transaction_ok = #{transaction_ok}"
    return transaction_ok
  end


  def check_nticks(nticks , naticks , nwticks )
    ok = true
    if @group.ntickets_by_occasion(@occasion).to_i < ( nticks.to_i + naticks.to_i + nwticks.to_i  )
      flash[:error] = "Du har bara #{@group.ntickets_by_occasion(@occasion)} platser du kan boka på den här föreställningen"
      ok = false
    elsif @occasion.wheelchair_seats < nwticks.to_i
      flash[:error] = "Det finns bara #{@occasion.available_wheelchair_seats} rullstolsplatser du kan boka på den här föreställningen"
      ok = false
    end
    return ok
  end
  
  def bork
    flash[:notice] = "Felaktiga parametrar"
    render :book
    return
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

    @groups = Group.find(
      Ticket.find(:all ,
        :select => "distinct group_id" ,
        :conditions => {:occasion_id => @occasion.id}
      ).map { |t| t.group_id})

    pp @groups
    pp params

    if params[:what] == "unbook" then
      #TODO : ta bort alla eller inga biljetter - annars gå via "ändra bokning"
      # Utför bokning och omdirigera till visa bokningar

      group = Group.find_by_id(params[:group_id])

      if group.nil?
        flash[:error] = "Ingen grupp angiven"
        redirect_to :controller => "booking", :action => "unbook", :occasion_id => params[:occasion_id]
        return
      end

      if params[:no_tickets].blank? || params[:no_tickets].to_i < 0
        flash[:error] = "Du måte ange antal biljetter du vill avboka"
        redirect_to :controller => "booking", :action => "unbook", :occasion_id => params[:occasion_id]
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

