class BookingRequirementsController < ApplicationController
  # GET /booking_requirements
  # GET /booking_requirements.xml
  def index
    @booking_requirements = BookingRequirement.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @booking_requirements }
    end
  end

  # GET /booking_requirements/1
  # GET /booking_requirements/1.xml
  def show
    @booking_requirement = BookingRequirement.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @booking_requirement }
    end
  end

  # GET /booking_requirements/new
  # GET /booking_requirements/new.xml
  def new
    @booking_requirement = BookingRequirement.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @booking_requirement }
    end
  end

  # GET /booking_requirements/1/edit
  def edit
    @booking_requirement = BookingRequirement.find(params[:id])
  end

  # POST /booking_requirements
  # POST /booking_requirements.xml
  def create
    @booking_requirement = BookingRequirement.new(params[:booking_requirement])

    respond_to do |format|
      if @booking_requirement.save
        flash[:notice] = 'BookingRequirement was successfully created.'
        format.html { redirect_to(@booking_requirement) }
        format.xml  { render :xml => @booking_requirement, :status => :created, :location => @booking_requirement }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @booking_requirement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /booking_requirements/1
  # PUT /booking_requirements/1.xml
  def update
    @booking_requirement = BookingRequirement.find(params[:id])

    respond_to do |format|
      if @booking_requirement.update_attributes(params[:booking_requirement])
        flash[:notice] = 'BookingRequirement was successfully updated.'
        format.html { redirect_to(@booking_requirement) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @booking_requirement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /booking_requirements/1
  # DELETE /booking_requirements/1.xml
  def destroy
    @booking_requirement = BookingRequirement.find(params[:id])
    @booking_requirement.destroy

    respond_to do |format|
      format.html { redirect_to(booking_requirements_url) }
      format.xml  { head :ok }
    end
  end
end
