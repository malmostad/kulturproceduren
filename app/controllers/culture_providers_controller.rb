class CultureProvidersController < ApplicationController
  # GET /culture_providers
  # GET /culture_providers.xml
  def index
    @culture_providers = CultureProvider.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @culture_providers }
    end
  end

  # GET /culture_providers/1
  # GET /culture_providers/1.xml
  def show
    @culture_provider = CultureProvider.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @culture_provider }
    end
  end

  # GET /culture_providers/new
  # GET /culture_providers/new.xml
  def new
    @culture_provider = CultureProvider.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @culture_provider }
    end
  end

  # GET /culture_providers/1/edit
  def edit
    @culture_provider = CultureProvider.find(params[:id])
  end

  # POST /culture_providers
  # POST /culture_providers.xml
  def create
    @culture_provider = CultureProvider.new(params[:culture_provider])

    respond_to do |format|
      if @culture_provider.save
        flash[:notice] = 'CultureProvider was successfully created.'
        format.html { redirect_to(@culture_provider) }
        format.xml  { render :xml => @culture_provider, :status => :created, :location => @culture_provider }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @culture_provider.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /culture_providers/1
  # PUT /culture_providers/1.xml
  def update
    @culture_provider = CultureProvider.find(params[:id])

    respond_to do |format|
      if @culture_provider.update_attributes(params[:culture_provider])
        flash[:notice] = 'CultureProvider was successfully updated.'
        format.html { redirect_to(@culture_provider) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @culture_provider.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /culture_providers/1
  # DELETE /culture_providers/1.xml
  def destroy
    @culture_provider = CultureProvider.find(params[:id])
    @culture_provider.destroy

    respond_to do |format|
      format.html { redirect_to(culture_providers_url) }
      format.xml  { head :ok }
    end
  end
end
