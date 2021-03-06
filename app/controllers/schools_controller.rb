# Controller for managing schools.
class SchoolsController < ApplicationController
  layout "application", except: [ :options_list ]
  
  before_filter :authenticate, except: [ :options_list, :select, :search ]
  before_filter :require_admin, except: [ :options_list, :select, :search ]

  def index
    if params[:filter] && params[:filter] == :external.to_s
      @schools = School.includes(:district).where.not(extens_id: nil).order(name: :asc).paginate(page: params[:page])
    elsif params[:filter] && params[:filter] == :manual.to_s
      @schools = School.includes(:district).where(extens_id: nil).order(name: :asc).paginate(page: params[:page])
    else
      @schools = School.includes(:district).order(name: :asc).paginate(page: params[:page])
    end
  end


  def show
    @districts = District.all
    @school = School.find(params[:id])
    @groups = @school.groups.order(sort_order("name")).paginate(page: params[:page])
  end

  def history
    @school = School.find(params[:id])
  end

  def new
    @school = School.new
    @school.district_id = params[:district_id] if params[:district_id]

    @districts = District.all
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
      @groups = @school.groups.order(sort_order("name")).paginate(page: params[:page])
      @districts = District.all
      render action: "show"
    end
  end

  def destroy
    @school = School.find(params[:id])
    district = @school.district
    @school.destroy

    flash[:notice] = "Skolan togs bort."
    redirect_to(district)
  end


  def search
    query = School.active.order(:name).limit(10)

    schools = query.name_search("#{params[:term]}%" )

    if schools.blank?
      schools = query.name_search("%#{params[:term]}%" )
    end

    render text: schools.collect(&:name).to_json, content_type: "text/plain"
  end

  # Selects a school for the working session. Used by the select group fragment
  # as step two when selecting district-school-group.
  def select
    if !params[:school_id].blank?
      school = School.find params[:school_id]
    else
      school = School.active.name_search(params[:school_name]).first!
    end

    session[:group_selection] = {
      district_id: school.district_id,
      school_id: school.id,
      school_name: school.name
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
