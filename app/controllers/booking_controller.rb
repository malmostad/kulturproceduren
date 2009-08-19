class BookingController < ApplicationController
  require "pp"
  
  before_filter :authenticate
  before_filter :require_booker
  
  layout "standard"


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
      :group => @group,
      :occasion => @occasion,
      :companion => @companion,
      :nticks => @nticks,
      :naticks => @naticks,
      :nwticks => @nwticks,
      :br => @br,
      :edit => @edit
    }, :content_type => 'text/plain'
  end

  def book

    begin
      @occasion = Occasion.find(params[:occasion_id])
    rescue
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end

    if @occasion.event.ticket_release_date > Date.today
      flash[:error] = "Föreställningen är inte bokningsbar före #{@occasion.event.ticket_release_date}"
      redirect_to "/"
      return
    end

    load_group_selection_collections(@occasion)

    @user = current_user
    @errors = {}

    if params[:create_booking]

      @curgroup = Group.find(params[:group_id])
      load_vars

      if Ticket.count(:all , :conditions => { :group_id => @curgroup.id , :event_id => @occasion.event.id , :state => Ticket::BOOKED }) > 0
        flash[:error] = "Gruppen #{@curgroup.name} #{@curgroup.school.name} har redan bokat biljetter på den här evenemanget."
        redirect_to "/"
        return
      end

      if params[:seats_students].to_i + params[:seats_adult].to_i + params[:seats_wheelchair].to_i == 0
        flash.now[:error] = "Du måste boka minst 1 biljett"
        render :book
        return
      end

      if !check_nticks(params[:seats_students], params[:seats_adult], params[:seats_wheelchair])
        render :book
        return
      else
        #Do booking

        unless @companion.save

          if @errors.keys.length == 0
            flash.now[:error] = "Kunde inte spara värdena för medföljande vuxen ... Försök igen?"
          end

          render :book
          return
        end

        unless @occasion.event.questionaire.blank?
          chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
          tempid = ""

          (1..45).each { |i| tempid << chars[rand(chars.size-1)] }

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
        if book_ticks(params[:seats_students].to_i, params[:seats_adult].to_i, params[:seats_wheelchair].to_i)
          flash[:notice] = "Du har bokat #{tot_requested} platser"
          redirect_to :controller => "booking" , :action => "show"
        else
          flash.now[:error] = "Kunde inte boka biljetterna ... Försök igen?"
          render :book
          return
        end
      end
    elsif params[:update_booking]

      load_vars

      if !@companion.blank? || @companion.name != params[:companion_name] || @companion.email != params[:companion_email] || @companion.tel_nr != params[:companion_telnr]

        @curgroup = @group

        @companion.name = params[:companion_name]
        @companion.email = params[:companion_email]
        @companion.tel_nr = params[:companion_telnr]

        if !@companion.save
          if @errors.keys.length == 0
            flash.now[:error] = "Kunde inte spara information ang med följande vuxen"
          end

          render :book
          return
        end

        if !check_nticks(params[:seats_students], params[:seats_adult], params[:seats_wheelchair])
          render :book
          return
        end
      end

      begin
        br = BookingRequirement.find(:first , :conditions => {:occasion_id => @occasion.id , :group_id => @group.id})
      rescue ActiveRecord::RecordNotFound
        br = nil
      end

      if params[:booking_request].blank? && !br.blank?
        br.delete
      end

      if !params[:booking_request].blank? && params[:booking_request] != br.requirement
        br.requirement = params[:booking_request]
        br.save or flash.now[:error] = "Kunde inte spara information ang. extra behov"
      end

      begin
        if params[:seats_students].to_i != @nticks || params[:seats_adult] != @naticks || params[:seats_wheelchair] != @nwticks
          Ticket.transaction do
            if not unbook_all_ticks()
              flash.now[:error] = "Kunde inte förändra antalet bokade biljetter"
              raise ActiveRecord::Rollback
            end

            if not book_ticks(params[:seats_students].to_i,params[:seats_adult].to_i,params[:seats_wheelchair].to_i)
              flash.now[:error] = "Kunde inte förändra antalet bokade biljetter"
              raise ActiveRecord::Rollback
            end
          end #transaction
        end
      rescue Exception
        redirect_to :controller => "booking" , :action => "book"
      end

      #TODO - return_to parameter
      redirect_to :controller => "booking" , :action => "show"
    elsif session[:group_selection][:group_id]
      @curgroup = Group.find(session[:group_selection][:group_id])
      params[:group_id] = @curgroup.id
      load_vars(false)
    end

  end

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
          flash.now[:error] = "Du försöker boka fler biljetter än vad som är tilldelat för gruppen på den här föreställningen."
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

  def show
    @user = current_user
  end

  def by_group
    @user = current_user
    load_group_selection_collections()

    begin
      @group = Group.find(session[:group_selection][:group_id])
    rescue ActiveRecord::RecordNotFound
      #Fall through and render default screen.....
    end

    if !@group.blank?
      oids = Ticket.find(:all , :select => "distinct occasion_id" , :conditions => { :group_id => @group.id , :state => Ticket::BOOKED})
      unless oids.blank?
        @occasions = Occasion.find( :all , oids.map{ |t| t.occasion_id } )
      else
        @occasions = []
      end

      @bookings = {}
      @bookings["#{@group.id}"] = @occasions
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

  def load_vars(validate = true)
    begin
      @group = Group.find(params[:group_id])
      @occasion = Occasion.find(params[:occasion_id])

      t = Ticket.find(
        :first,
        :conditions => {
          :group_id => @group.id,
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

    if validate && params[:companion_telnr].blank?
      @errors["companion_telnr"] = "Du måste ange telefonnummer för medföljande vuxen"
    end

    @companion.tel_nr = params[:companion_telnr]

    if validate && params[:companion_email].blank?
      @errors["companion_email"] = "Du måste ange epostaddress för medföljande vuxen"
    end
    @companion.email = params[:companion_email]

    if validate && params[:companion_name].blank?
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
      end
    end
  end

  def check_nticks(nticks, naticks, nwticks)
    ok = true

    if @group.available_tickets_by_occasion(@occasion).to_i < ( nticks.to_i + naticks.to_i + nwticks.to_i  )
      @errors["nticks"] = "Du har bara #{@group.available_tickets_by_occasion(@occasion)} platser du kan boka på den här föreställningen"
      ok = false
    elsif @occasion.wheelchair_seats < nwticks.to_i
      @errors["nwticks"] = "Det finns bara #{@occasion.available_wheelchair_seats} rullstolsplatser du kan boka på den här föreställningen"
      ok = false
    end
    return ok
  end

  def require_booker
    unless current_user.can_book?
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to "/"
    end
  end
end

