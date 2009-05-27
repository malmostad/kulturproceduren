class SchoolsController < ApplicationController
  layout "admin"
  
  def index
    @schools = School.all :order => "name ASC", :include => :district
  end

  def show
    @school = School.find(params[:id])
  end

  def new
    @school = School.new
    @school.district_id = params[:district_id] if params[:district_id]

    @districts = District.all
  end

  def edit
    @school = School.find(params[:id])
    @districts = District.all
    render :action => "new"
  end

  def create
    @school = School.new(params[:school])

    if @school.save
      prio = SchoolPrio.new do |p|
        p.school = @school
        p.district = @school.district
        p.prio = SchoolPrio.max_prio(@school.district) + 1
      end
      prio.save!

      flash[:notice] = 'Skolan skapades.'
      redirect_to(@school)
    else
      @districts = District.all
      render :action => "new"
    end
  end

  def update
    @school = School.find(params[:id])

    new_district = @school.district_id.to_i != params[:school][:district_id].to_i

    if @school.update_attributes(params[:school])

      if new_district
        @school.school_prio.district = @school.district
        @school.school_prio.prio = SchoolPrio.max_prio(@school.district) + 1
        @school.school_prio.save!
      end

      flash[:notice] = 'Skolan uppdaterades.'
      redirect_to(@school)
    else
      @districts = District.all
      render :action => "new"
    end
  end

  def destroy
    @school = School.find(params[:id])
    district = @school.district
    @school.destroy

    flash[:notice] = "Skolan togs bort."
    redirect_to(district)
  end
end
