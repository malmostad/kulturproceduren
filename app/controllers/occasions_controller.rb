# Controller for managing occasions
class OccasionsController < ApplicationController

  layout "standard"
  
  require "pdf/writer"
  require "pdf/simpletable"

  before_filter :authenticate, :except => [ :index, :show ]
  before_filter :require_culture_worker, :only => [ :edit, :update, :destroy ]
  before_filter :require_host, :only => [ :report_show , :report_create ]


  # Displays a form for reporting the attendance on an occasion
  def report_show

    if params[:id].blank? || params[:id].to_i == 0
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end

    begin
      @occasion = Occasion.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Kunde inte hitta angiven föreställning"
      redirect_to "/"
      return
    end

    if @occasion.date > Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to "/"
      return
    end

    @groups = Group.find Ticket.find(
      :all ,
      :select => "distinct group_id" ,
      :conditions => {
        :occasion_id => @occasion.id ,
        :state => Ticket::BOOKED
      } ).map { |t| t.group_id }

    render :report

  end

  # Creates an attendace report from the form parameters
  def report_create
    if params[:id].blank? or params[:id].to_i == 0
      flash[:error] = "Ingen föreställning angiven"
      redirect_to "/"
      return
    end

    begin
      @occasion = Occasion.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Kunde inte hitta angiven föreställning"
      redirect_to "/"
      return
    end

    if @occasion.date > Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to "/"
      return
    end

    @groups = Group.find Ticket.find(
      :all ,
      :select => "distinct group_id" ,
      :conditions => {
        :occasion_id => @occasion.id ,
        :state => Ticket::BOOKED
      } ).map { |t| t.group_id }

    if !params[:groups].blank?
      @report_complete = false
      @reported_groups = {}

      #allow only numerical gids and number of attendees
      #
      params[:groups].select { |gid,nattend|
        nattend.to_i > 0 and gid.to_i > 0
      }.map { |gids,nattends|
        @reported_groups["#{gids}"] = nattends
      }
      @report_complete = @reported_groups.keys.map {|k| k.to_i }.sort == @groups.map {|g| g.id}.sort
    end

    if @report_complete
      @groups.each do |group|
        tickets = Ticket.find(
          :all ,
          :conditions => {
            :occasion_id => @occasion.id ,
            :group_id => group.id ,
            :state => Ticket::BOOKED
          }
        )

        n = 0

        tickets.each do |ticket|
          if n < params[:groups]["#{group.id}"].to_i
            ticket.state = Ticket::USED
          else
            ticket.state = Ticket::NOT_USED
          end

          ticket.save or flash[:error] = "Kunde inte uppdatera närvarostatistiken ..."
          n += 1
        end
      end
      flash[:notice] = "Tack för närvarorapporten"
      redirect_to "/"
    else
      flash[:error] = "Rapporten inkomplett"
      render :report
    end
  end


  # Displays a list of the groups attending the occasion,
  # as a HTML page or a PDF.
  def attendants
    @occasion = Occasion.find(params[:id])

    group_ids = Ticket.find(
      :all ,
      :select => "distinct group_id" ,
      :conditions => {
        :occasion_id => @occasion.id ,
        :state => Ticket::BOOKED
      } ).map { |t| t.group_id }

    if params[:format] == "pdf"
      @groups = Group.find group_ids
    else
      @groups = Group.paginate group_ids, :page => params[:page], :order => 'updated_at DESC'
    end

    @booking_reqs = BookingRequirement.find_all_by_group_id(
      @groups.map { |g| g.id } ,
      :conditions => { :occasion_id => @occasion.id }
    )

    if params[:format] == "pdf"
      pdf = get_pdf()
      send_data pdf.render, :filename => "attendants.pdf",:type => "application/pdf" , :disposition => 'inline'
    end

  end

  # Displays a specific occasion as the part of an event presentation
  def show
    @selected_occasion = Occasion.find(params[:id])
    @event = @selected_occasion.event

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


  private

  # Creates a pdf document of the attendants on an occasion
  def get_pdf

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
        row["att"]     = g.available_tickets_by_occasion(@occasion,Ticket::BOOKED).to_s.to_iso
        row["wheel"]   = g.available_tickets_by_occasion(@occasion,Ticket::BOOKED,true).to_s.to_iso
        row["req"]     = @booking_reqs.select { |b| b.group_id == g.id }.map { |b| (b.requirement.to_s + "\n").to_iso  }
        row["pres"]    = " ".to_iso
        data << row
      end
      tab.data.replace data
      tab.render_on(pdf)
    end

    return pdf
  end

  # Checks if the user is a host. For use in +before_filter+.
  def require_host
    @user = current_user

    unless @user.has_role?(:host) || @user.has_role?(:admin)
      flash[:error] = "Du har inte behörighet att rapportera närvaro"
      redirect_to "/"
      return
    end
  end

  # Checks if the user has administration privileges on the occasion.
  # For use in +before_filter+.
  def require_culture_worker
    @occasion = Occasion.find(params[:id])

    unless current_user.can_administrate?(@occasion.event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @occasion.event
    end
  end
end
