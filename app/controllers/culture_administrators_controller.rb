class CultureAdministratorsController < ApplicationController
  # GET /culture_administrators
  # GET /culture_administrators.xml
  def index
    @culture_administrators = CultureAdministrator.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @culture_administrators }
    end
  end

  # GET /culture_administrators/1
  # GET /culture_administrators/1.xml
  def show
    @culture_administrator = CultureAdministrator.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @culture_administrator }
    end
  end

  # GET /culture_administrators/new
  # GET /culture_administrators/new.xml
  def new
    @culture_administrator = CultureAdministrator.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @culture_administrator }
    end
  end

  # GET /culture_administrators/1/edit
  def edit
    @culture_administrator = CultureAdministrator.find(params[:id])
  end

  # POST /culture_administrators
  # POST /culture_administrators.xml
  def create
    @culture_administrator = CultureAdministrator.new(params[:culture_administrator])

    respond_to do |format|
      if @culture_administrator.save
        flash[:notice] = 'CultureAdministrator was successfully created.'
        format.html { redirect_to(@culture_administrator) }
        format.xml  { render :xml => @culture_administrator, :status => :created, :location => @culture_administrator }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @culture_administrator.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /culture_administrators/1
  # PUT /culture_administrators/1.xml
  def update
    @culture_administrator = CultureAdministrator.find(params[:id])

    respond_to do |format|
      if @culture_administrator.update_attributes(params[:culture_administrator])
        flash[:notice] = 'CultureAdministrator was successfully updated.'
        format.html { redirect_to(@culture_administrator) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @culture_administrator.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /culture_administrators/1
  # DELETE /culture_administrators/1.xml
  def destroy
    @culture_administrator = CultureAdministrator.find(params[:id])
    @culture_administrator.destroy

    respond_to do |format|
      format.html { redirect_to(culture_administrators_url) }
      format.xml  { head :ok }
    end
  end
end
