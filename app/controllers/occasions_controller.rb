class OccasionsController < ApplicationController

  layout "standard"
  require "pdf/writer"
  require "pdf/simpletable"

  before_filter :authenticate, :except => [ :index, :show , :attlist , :attlist_pdf]

  def attlist
    @occasion = Occasion.find(params[:id])
    if @occasion.nil?
      flash[:error] = "Felaktiga parametrar"
      redirect_to "/"
      return
    end
    
    @groups = Group.find(
      Ticket.find(
        :all ,
        :select => "distinct group_id" ,
        :conditions => {
          :occasion_id => 1 ,
          :state => Ticket::BOOKED
        } ).map { |t| t.group_id} )

    @brs = BookingRequirement.find_all_by_group_id(
      @groups.map {|g| g.id} ,
      :conditions => { :occasion_id => @occasion.id }
    )

    @ntickets = @groups.map { |g| g.ntickets_by_occasion(@occasion,Ticket::BOOKED) }

    render "attlist"

  end

def attlist_pdf
    @occasion = Occasion.find(params[:id])
    if @occasion.nil?
      flash[:error] = "Felaktiga parametrar"
      redirect_to "/"
      return
    end

    @groups = Group.find(
      Ticket.find(
        :all ,
        :select => "distinct group_id" ,
        :conditions => {
          :occasion_id => 1 ,
          :state => Ticket::BOOKED
        } ).map { |t| t.group_id} )

    @brs = BookingRequirement.find_all_by_group_id(
      @groups.map {|g| g.id} ,
      :conditions => { :occasion_id => @occasion.id }
    )

    @ntickets = @groups.map { |g| g.ntickets_by_occasion(@occasion,Ticket::BOOKED) }

    pdf = PDF::Writer.new  :paper => "A4" , :orientation => :landscape
    pdf.select_font("Helvetica")
    pdf.margins_cm(2,2,2,2)
    

    PDF::SimpleTable.new do |tab|
      tab.title = "Deltagarlista för #{@occasion.event.name} #{@occasion.date.to_s}".to_iso
      tab.column_order.push(*%w(group comp comptel att wheel req pres))

      tab.columns["group"] = PDF::SimpleTable::Column.new("group") { |col|
          col.heading = "Skola / Grupp".to_iso
      }
      tab.columns["comp"] = PDF::SimpleTable::Column.new("com") { |col|
          col.heading = "Medföljande vuxen".to_iso
      }
      tab.columns["comptel"] = PDF::SimpleTable::Column.new("comptel") { |col|
        col.heading = "Telefonnummer"
      }
      tab.columns["att"] = PDF::SimpleTable::Column.new("att") { |col|
        col.heading = "Deltagare"
      }
      tab.columns["wheel"] = PDF::SimpleTable::Column.new("wheel") { |col|
        col.heading = "Rullstolsplatser"
      }
      tab.columns["req"]  = PDF::SimpleTable::Column.new("req") { |col|
        col.heading = "Övriga önskemål".to_iso
      }
      tab.columns["pres"]  = PDF::SimpleTable::Column.new("pres") { |col|
        col.heading = "Antal närvarande".to_iso
      }

      tab.show_lines    = :all
      tab.show_headings = true
      #tab.orientation   = :right
      tab.orientation   = 1
      tab.position      = :left
      tab.font_size     = 9
      tab.maximum_width = 1
      puts "DEBUGG: #{tab.maximum_width}"
      data = []
      @groups.each do |g|
        row = {}
        row["group"]   = (g.school.name.to_s + " - " + g.name.to_s).to_iso
        row["comp"]    = g.companion_by_occasion(@occasion).name.to_iso
        row["comptel"] = g.companion_by_occasion(@occasion).tel_nr.to_s.to_iso
        row["att"]     = g.ntickets_by_occasion(@occasion,Ticket::BOOKED).to_s.to_iso
        row["wheel"]   = g.ntickets_by_occasion(@occasion,Ticket::BOOKED,true).to_s.to_iso
        row["req"]     = @brs.select { |b| b.group_id == g.id }.map { |b| (b.requirement.to_s + "\n").to_iso  }
        row["pres"]    = " ".to_iso
        data << row
      end
      tab.data.replace data
      tab.render_on(pdf)
    end
    send_data pdf.render, :filename => "deltagarlista.pdf",:type => "application/pdf" , :disposition => 'inline'
  end

  def index
    @today = Date.today

    @visible_events = Event.visible.find :all
    @visible_occasions = []

    @visible_events.each do |e|
      o = Occasion.find(:all, :conditions => "event_id = #{e.id}")
      o.each do |oo|
        @visible_occasions.push(oo)
      end
    end

    @user = current_user
    @user_events = Event.visible_events_by_userid(@user.id)
    @user_events_hash_by_id = {}

    @user_events.each do |e|
      @user_events_hash_by_id[e.id] = e
    end

  end

  def show
    @selected_occasion = Occasion.find(params[:id])
    @event = @selected_occasion.event

    render :template => "events/show"
  end

  def edit
    @occasion = Occasion.find(params[:id])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
      return
    end

    @event = @occasion.event

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
      flash[:notice] = 'Föreställningen skapades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      render :template => "events/show"
    end
  end

  def update
    @occasion = Occasion.find(params[:id])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
      return
    end

    if @occasion.update_attributes(params[:occasion])
      flash[:notice] = 'Föreställningen uppdaterades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      render :template => "events/show"
    end
  end

  def destroy
    @occasion = Occasion.find(params[:id])

    if current_user.can_administrate?(@occasion.event.culture_provider)
      @occasion.destroy
    else
      flash[:error] = "Du har inte behörighet att komma åt sidan."
    end

    redirect_to(@occasion.event)
  end
end
