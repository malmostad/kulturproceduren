# Controller for managing schools.
class SchoolsController < ApplicationController
  layout "admin", except: [ :options_list ]
  
  before_filter :authenticate, except: [ :options_list, :select ]
  before_filter :require_admin, except: [ :options_list, :select ]

  def index
    @schools = School.includes(:district).order(sort_order("name")).paginate(page: params[:page])
  end


  def show
    @school = School.find(params[:id])
    @groups = @school.groups.order(sort_order("name")).paginate(page: params[:page])
  end

  def new
    @school = School.new
    @school.district_id = params[:district_id] if params[:district_id]

    @districts = District.all
  end

  def edit
    @school = School.find(params[:id])
    @districts = District.all
    render action: "new"
  end

  def create
    @school = School.new(params[:school])

    if @school.save
      flash[:notice] = 'Skolan skapades.'
      redirect_to(@school)
    else
      @districts = District.all
      render action: "new"
    end
  end

  def update
    @school = School.find(params[:id])

    if @school.update_attributes(params[:school])
      flash[:notice] = 'Skolan uppdaterades.'
      redirect_to(@school)
    else
      @districts = District.all
      render action: "new"
    end
  end

  def destroy
    @school = School.find(params[:id])
    district = @school.district
    @school.destroy

    flash[:notice] = "Skolan togs bort."
    redirect_to(district)
  end


  # Selects a school for the working session. Used by the select group fragment
  # as step two when selecting district-school-group.
  def select
    school = School.find params[:school_id]
    session[:group_selection] = {
      district_id: school.district_id,
      school_id: school.id
    }
  rescue
  ensure
    if request.xhr?
      render text: "", content_type: "text/plain"
    else
      redirect_to params[:return_to]
    end
  end

  # Renders a HTML select option list as a fragment for use in an Ajax call.
  def options_list
    conditions = {}

    district_id = params[:district_id].to_i
    occasion_id = params[:occasion_id].to_i

    if (params[:district_id] && district_id <= 0) || (params[:occasion_id] && occasion_id <= 0)
      render text: "", content_type: 'text/plain', status: 404
      return
    end

    if district_id > 0
      conditions[:district_id] = district_id

      district = District.find params[:district_id]
      session[:group_selection] = { district_id: district.id }
    end

    if occasion_id > 0
      occasion = Occasion.find occasion_id
      @schools = School.where(conditions).select { |s|
        s.available_tickets_by_occasion(occasion) > 0
      }
    else
      @schools = School.where(conditions).order("name ASC")
    end

    render action: "options_list", content_type: 'text/plain'
  rescue => e
    logger.debug(e)
    render text: "", content_type: 'text/plain', status: 404
  end

  protected

  # Sort schools by their names by default.
  def sort_column_from_param(p)
    return "name" if p.blank?

    case p.to_sym
    when :district then "districts.name"
    when :elit_id then "elit_id"
    when :active then "active"
    else
      "name"
    end
  end
end
