class SchoolsController < ApplicationController
  layout "admin", :except => [ :options_list ]
  
  before_filter :authenticate, :except => [ :options_list ]
  before_filter :require_admin, :except => [ :options_list ]

  def index
    @schools = School.paginate :page => params[:page],
      :order => sort_order("name"),
      :include => :district
  end

  def options_list
    if params[:district_id]
      if params[:occasion_id].blank? or params[:occasion_id].to_i == 0
        @schools = School.all :order => "name ASC", :conditions => { :district_id => params[:district_id] }
      else
        @occasion = Occasion.find(params[:occasion_id])
        @schools = School.find(
          :all ,
          :conditions => { :district_id => params[:district_id] }
        ).select { |s|
          s.available_tickets_per_occasion(@occasion) > 0
        }
      end
    else
      if params[:occasion_id].blank? or params[:occasion_id].to_i == 0
        @schools = School.all :order => "name ASC"
      else
        @occasion = Occasion.find(params[:occasion_id])
        @schools = School.all.select { |s|
          s.available_tickets_per_occasion(@occasion) > 0
        }
      end
    end

    sleep 3
    render :action => "options_list", :content_type => 'text/plain'
  end

  def show
    @school = School.find(params[:id])
    @groups = @school.groups.paginate :page => params[:page],
      :order => sort_order("name")
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
        p.prio = SchoolPrio.lowest_prio(@school.district) + 1
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
        @school.school_prio.prio = SchoolPrio.lowest_prio(@school.district) + 1
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

  protected

  def sort_column_from_param(p)
    return "name" if p.blank?
    
    case p.to_sym
    when :district then "districts.name"
    when :elit_id then "elit_id"
    else
      "name"
    end
  end
end
