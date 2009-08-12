class BookingController < ApplicationController
  require "pp"
  
  before_filter :authenticate
  before_filter :check_booker
  
  layout "standard"

  def load_vars
    begin
      @group = Group.find(params[:group_id].to_i)
      @occasion = Occasion.find(params[:occasion_id].to_i)
      t = Ticket.find(
        :first ,
        :conditions => {
          :group_id => @group.id ,
          :occasion_id => @occasion.id
        }
      )
    rescue ActiveRecord::RecordNotFound
      puts "Inga biljetter bokade"
    end
    @nticks  = params[:seats_students].to_i
    @naticks = params[:seats_adult].to_i
    @nwticks = params[:seats_wheelchair].to_i
    check_nticks( @nticks, @naticks, @nwticks)
    @companion = Companion.new

    @br = BookingRequirement.new
    @br.occasion = @occasion
    @br.group = @curgroup
    @br.requirement = params[:booking_request]

    if params[:companion_telnr].blank? && ( params[:commit] == "Ändra bokning" or params[:commit] == "Boka" )
      @errors["companion_telnr"] = "Du måste ange telefonnummer för medföljande vuxen"
    end
    @companion.tel_nr = params[:companion_telnr]

    if params[:companion_email].blank? and ( params[:commit] == "Ändra bokning" or params[:commit] == "Boka" )
      @errors["companion_email"] = "Du måste ange epostaddress för medföljande vuxen"
    end
    @companion.email = params[:companion_email]

    if params[:companion_name].blank? && ( params[:commit] == "Ändra bokning" or params[:commit] == "Boka" )
      @errors["companion_name"] = "Du måste ange namn för medföljande vuxen"
    end
    
    @companion.name  = params[:companion_name]

    if t.blank?
      @edit = false
    else
      @edit = true
      begin
        @companion = Companion.find(t.companion_id)
        @br = BookingRequirement.find(
          :first ,
          :conditions => {
            :group_id => @group.id ,
            :occasion_id => @occasion.id
          }
        )
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
      rescue ActiveRecord::RecordNotFound
        puts "Inga extra behov eller ingen companion på denna bokning"
      end
    end
  end

  def get_by_group_list
    begin
      @group = Group.find(params[:group_id])
      oids = Ticket.find(:all , :select => "distinct occasion_id" , :conditions => { :group_id => @group.id , :state => Ticket::BOOKED})
      @occasions = Occasion.find( :all , oids.map{ |t| t.occasion_id } )
      #TODO : rescue
    rescue ActiveRecord::RecordNotFound
    end
    unless oids.blank?
      @occasions = Occasion.find( :all , oids.map{ |t| t.occasion_id } )
    else
      @occasions = []
    end

    render :partial => "by_group_list", :content_type => "text/plain",
      :locals => {
      :occasions => @occasions ,
      :group => @group
    }

  end

  def get_input_area
    @group = Group.find(params[:group_id])
    @occasion = Occasion.find(params[:occasion_id])
    @errors = Hash.new
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
    }, :content_type => 'text/plain'
  end

  def populate_districts_list
    if @occasion.blank?
      return nil
    end
    @districts = District.all.select { |d| 
      d.available_tickets_per_occasion(@occasion) > 0 
    }
  end

  def populate_schools_list
    if @occasion.blank?
      return nil
    end
    if params[:district_id].blank? or params[:district_id].to_i == 0
      return nil
    end
    @schools = School.find(
      :all ,
      :conditions => { :district_id => params[:district_id] }
    ).select { |s|
      s.available_tickets_per_occasion(@occasion) > 0
    }
  end

  def populate_groups_list
    if @occasion.blank?
      return nil
    end
    if params[:school_id].blank? or params[:school_id].to_i == 0
      return nil
    end
    @groups = Group.find(
      :all ,
      :conditions => { :school_id => params[:school_id] }
    ).select { |g|
      g.ntickets_by_occasion(@occasion) > 0
    }
  end

  def book

    @user = current_user
    @errors = {}
    if params[:occasion_id].blank? || params[:occasion_id].to_i == 0
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

    if @occasion.event.ticket_release_date > Date.today
      flash[:error] = "Föreställningen är inte bokningsbar före #{@occasion.event.ticket_release_date}"
      redirect_to "/"
      return
    end
    
    populate_districts_list
    puts "In booking controller - method book districts ="
    
    #    if ( not params[:group_id].blank? ) && @curgroup = Group.find(params[:group_id])
    #      params[:commit] = "Välj grupp"
    #      params[:district_id] = @curgroup.school.district.id
    #      params[:school_id] = @curgroup.school.id
    #    end

    if params[:commit] == "Hämta skolor" && !params[:district_id].nil? && params[:district_id].to_i != 0
      populate_schools_list
    elsif params[:commit] == "Hämta grupper"
      if not params[:district_id].nil? && params[:district_id].to_i != 0 && !params[:school_id].nil? && params[:school_id].to_i != 0
        populate_schools_list
        populate_groups_list
      else
        bork
      end
    elsif params[:commit] == "Välj grupp"
      load_vars
      if not @group.blank?
        params[:district_id] = @group.school.district.id
        params[:school_id] = @group.school.id
      end
      if not params[:district_id].nil? && params[:district_id].to_i != 0 && !params[:school_id].nil? && params[:school_id].to_i != 0 && !params[:group_id].nil? && params[:group_id].to_i != 0
        populate_schools_list
        populate_groups_list
        @curgroup = Group.find(params[:group_id].to_i)
        if Ticket.count(:all , :conditions => { :group_id => @curgroup.id , :event_id => @occasion.event.id , :state => Ticket::BOOKED }) > 0
          flash[:notice] = "Gruppen #{@curgroup.name} #{@curgroup.school.name} har redan bokat biljetter på den här evenemanget."
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
      populate_schools_list
      populate_groups_list
      @curgroup = Group.find(params[:group_id])
      load_vars
      params[:commit] = "Välj grupp"
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

      if params[:seats_students].to_i + params[:seats_adult].to_i + params[:seats_wheelchair].to_i == 0
        flash[:error] = "Du måste boka minst 1 biljett"
        render :book
        return
      end
      #check_ntick sets flash-error message

      if not check_nticks(params[:seats_students],params[:seats_adult],params[:seats_wheelchair])
        render :book
        return
      else
        #Do booking

        unless @companion.save
          if @errors.keys.length == 0
            flash[:error] = "Kunde inte spara värdena för medföljande vuxen ... Försök igen?"
          end
          render :book
          return
        end

        unless @occasion.event.questionaire.blank?
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
      populate_schools_list
      populate_groups_list
      puts "Ändra bokning"
      load_vars
      params[:commit] = "Välj grupp"
      if ( not @companion.blank? or @companion.name != params[:companion_name] or @companion.email != params[:companion_email] or @companion.tel_nr != params[:companion_telnr]  )
        @curgroup = @group
        @companion.name = params[:companion_name]
        @companion.email = params[:companion_email]
        @companion.tel_nr = params[:companion_telnr]

        if not @companion.save
          if @errors.keys.length == 0
            flash[:error] = "Kunde inte spara information ang med följande vuxen"
          end
          render :book
          return
        end
        if not check_nticks(params[:seats_students],params[:seats_adult],params[:seats_wheelchair])
          render :book
          return
        end
      end
      begin
        br = BookingRequirement.find(:first , :conditions => {:occasion_id => @occasion.id , :group_id => @group.id})
      rescue ActiveRecord::RecordNotFound
        br = nil
      end
      if params[:booking_request].blank? and ( not br.blank? )
        br.delete
      end
      if not params[:booking_request].blank? && params[:booking_request] != br.requirement
        br.requirement = params[:booking_request]
        br.save or flash[:error] = "Kunde inte spara information ang. extra behov"
      end
      begin
        if params[:seats_students].to_i != @nticks || params[:seats_adult] != @naticks || params[:seats_wheelchair] != @nwticks
          Ticket.transaction do
            if not unbook_all_ticks()
              flash[:error] = "Kunde inte förändra antalet bokade biljetter"
              raise ActiveRecord::Rollback
            end
            if not book_ticks(params[:seats_students].to_i,params[:seats_adult].to_i,params[:seats_wheelchair].to_i)
              flash[:error] = "Kunde inte förändra antalet bokade biljetter"
              raise ActiveRecord::Rollback
            end
          end #transaction
        end
      rescue Exception
        redirect_to :controller => "booking" , :action => "book"
      end
      #TODO - return_to parameter
      redirect_to :controller => "booking" , :action => "show"
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
    nreq_ticks = nreq_ticks.to_i
    nreq_aticks = nreq_aticks.to_i
    nreq_wticks = nreq_wticks.to_i
    if not check_nticks(nreq_ticks.to_i , nreq_aticks.to_i , nreq_wticks.to_i )
      return false
    end
    tot_requested = nreq_ticks.to_i + nreq_aticks.to_i + nreq_wticks.to_i
    transaction_ok = true
    begin
      Ticket.transaction do
        #Dubbelkoll inne i transaktionen
        tickets = @group.bookable_tickets(@occasion,true)
        
        if tickets.length < tot_requested
          flash[:error] = "Du försöker boka fler biljetter än vad som är tilldelat för gruppen på den här föreställningen."
          render :book
          return
        end

        booked_tickets = 0
        booked_adult_tickets = 0
        booked_wheelchair_tickets = 0

        while booked_tickets < tot_requested
          tickets[booked_tickets].state = Ticket::BOOKED
          tickets[booked_tickets].group = @group
          tickets[booked_tickets].companion = @companion
          tickets[booked_tickets].user = @user
          tickets[booked_tickets].occasion = @occasion
          tickets[booked_tickets].wheelchair = false
          tickets[booked_tickets].adult = false
          tickets[booked_tickets].booked_when = DateTime.now
          if booked_adult_tickets.to_i < nreq_aticks.to_i
            tickets[booked_tickets].adult = true
            booked_adult_tickets += 1
          elsif booked_wheelchair_tickets.to_i < nreq_wticks.to_i
            tickets[booked_tickets].wheelchair = true
            booked_wheelchair_tickets += 1
          end
          retval = tickets[booked_tickets].save
          unless retval
            transaction_ok = false
            raise ActiveRecord::Rollback
          end
          booked_tickets +=1
        end
      end
    rescue Exception
      transaction_ok = false
    end
    return transaction_ok
  end


  def check_nticks(nticks , naticks , nwticks )
    ok = true
    if @group.ntickets_by_occasion(@occasion).to_i < ( nticks.to_i + naticks.to_i + nwticks.to_i  )
      @errors["nticks"] = "Du har bara #{@group.ntickets_by_occasion(@occasion)} platser du kan boka på den här föreställningen"
      ok = false
    elsif @occasion.wheelchair_seats < nwticks.to_i
      @errors["nwticks"] = "Det finns bara #{@occasion.available_wheelchair_seats} rullstolsplatser du kan boka på den här föreställningen"
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

  def by_group
    load_vars
    @user = current_user
    begin
      @group = Group.find(params[:by_group_group_id])
    rescue ActiveRecord::RecordNotFound
      #Fall through and render default screen.....
    end
    if not @group.blank?
      begin
        oids = Ticket.find(:all , :select => "distinct occasion_id" , :conditions => { :group_id => @group.id , :state => Ticket::BOOKED})
        unless oids.blank?
          @occasions = Occasion.find( :all , oids.map{ |t| t.occasion_id } )
          pp @occasions
        else
          @occasions = []
        end
        params[:by_group_district_id] = @group.school.district.id
        @schools = School.find :all , :conditions => { :district_id => @group.school.district.id }
        @groups  = Group.find :all , :conditions => { :school_id => @group.school.id }
        @curgroup = Group.find(params[:group_id])
        params[:commit] = "Välj grupp"
        @bookings = {}
        @bookings["#{@group.id}"] = @occasions
        pp @bookings
        #TODO : rescue
      end
    elsif not ( params[:school_id].blank? or params[:school_id] == "Välj stadsdel först" or params[:school_id] == "Hämta grupper" )
      @schools = School.find :all , :conditions => { :district_id => params[:by_group_district_id] }
      @groups  = Group.find :all , :conditions => { :school_id => params[:school_id] }
    elsif not ( params[:by_group_district_id].blank? or params[:by_group_district_id] == "Välj stadsdel först" )
      @schools = School.find :all , :conditions => { :district_id => params[:by_group_district_id] }
    else
      params[:commit] = "inge bra"
    end
  end

  def unbook
    @user = current_user
    if params[:return_to].blank?
      return_to = "show"
    else
      return_to = params[:return_to]
    end
    load_vars
    if @occasion.nil?
      flash[:error] = "Ingen föreställning angiven"
      redirect_to :controller => "booking" , :action => return_to
      return
    end
    if @group.nil?
      flash[:error] = "Ingen grupp angiven"
      redirect_to :controller => "booking" , :action => return_to
      return
    end

    if @nticks.blank? or @nticks == 0
      flash[:info] = "Ingen bokning gjord för #{@group.name}, #{@group.school.name} på denna föreställning"
    else
      begin
        if @companion.delete and @br.delete and unbook_all_ticks()
          flash[:info] = "Bokning borttagen"
        else
          flash[:error] = "Kunde inte avboka"
        end
      end
    end
    redirect_to :controller => "booking" , :action => return_to , :group_id => @group.id
  end

  private

  def check_booker
    unless current_user.can_book?
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to "/"
    end
  end
end

