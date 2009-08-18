class SchoolsController < ApplicationController
  layout "admin", :except => [ :options_list ]
  
  before_filter :authenticate, :except => [ :options_list, :select ]
  before_filter :require_admin, :except => [ :options_list, :select ]

  def index
    @schools = School.paginate :page => params[:page],
      :order => sort_order("name"),
      :include => :district
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


  def select
    school = School.find params[:school_id]
    session[:group_selection] = {
      :district_id => school.district_id,
      :school_id => school.id
    }
  rescue
  ensure
    if request.xhr?
      render :text => "", :content_type => "text/plain"
    else
      redirect_to params[:return_to]
    end
  end

  def options_list
    conditions = {}

    district_id = params[:district_id].to_i
    occasion_id = params[:occasion_id].to_i

    if (params[:district_id] && district_id <= 0) || (params[:occasion_id] && occasion_id <= 0)
      render :text => "", :content_type => 'text/plain', :status => 404
      return
    end

    if district_id > 0
      conditions[:district_id] = district_id

      district = District.find params[:district_id]
      session[:group_selection] = { :district_id => district.id }
    end

    if occasion_id > 0
      occasion = Occasion.find occasion_id
      @schools = School.find(:all, :conditions => conditions).select { |s|
        s.available_tickets_by_occasion(occasion) > 0
      }
    else
      @schools = School.all :order => "name ASC", :conditions => conditions
    end

    render :action => "options_list", :content_type => 'text/plain'
  rescue
    render :text => "", :content_type => 'text/plain', :status => 404
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
