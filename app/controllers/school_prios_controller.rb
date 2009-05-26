class SchoolPriosController < ApplicationController
  layout "standard"
  
  # GET /school_prios
  # GET /school_prios.xml
  def index
    @school_prios = SchoolPrio.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @school_prios }
    end
  end

  # GET /school_prios/1
  # GET /school_prios/1.xml
  def show
    @school_prio = SchoolPrio.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @school_prio }
    end
  end

  # GET /school_prios/new
  # GET /school_prios/new.xml
  def new
    @school_prio = SchoolPrio.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @school_prio }
    end
  end

  # GET /school_prios/1/edit
  def edit
    @school_prio = SchoolPrio.find(params[:id])
  end

  # POST /school_prios
  # POST /school_prios.xml
  def create
    @school_prio = SchoolPrio.new(params[:school_prio])

    respond_to do |format|
      if @school_prio.save
        flash[:notice] = 'SchoolPrio was successfully created.'
        format.html { redirect_to(@school_prio) }
        format.xml  { render :xml => @school_prio, :status => :created, :location => @school_prio }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @school_prio.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /school_prios/1
  # PUT /school_prios/1.xml
  def update
    @school_prio = SchoolPrio.find(params[:id])

    respond_to do |format|
      if @school_prio.update_attributes(params[:school_prio])
        flash[:notice] = 'SchoolPrio was successfully updated.'
        format.html { redirect_to(@school_prio) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @school_prio.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /school_prios/1
  # DELETE /school_prios/1.xml
  def destroy
    @school_prio = SchoolPrio.find(params[:id])
    @school_prio.destroy

    respond_to do |format|
      format.html { redirect_to(school_prios_url) }
      format.xml  { head :ok }
    end
  end
end
