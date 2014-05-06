# Controller for managing districts
class DistrictsController < ApplicationController
  layout "admin"
  
  before_filter :authenticate
  before_filter :require_admin, except: [ :select ]

  def index
    @districts = District.includes(:school_type).order(sort_order("name")).paginate page: params[:page]
  end

  def show
    @district = District.find(params[:id])
  end

  def new
    @school_types = SchoolType.order(:name)
    @district = District.new
  end

  def edit
    @school_types = SchoolType.order(:name)
    @district = District.find(params[:id])
    render action: "new"
  end

  def create
    @district = District.new(params[:district])

    if @district.save
      flash[:notice] = 'Området skapades.'
      redirect_to(@district)
    else
      @school_types = SchoolType.order(:name)
      render action: "new"
    end
  end

  def update
    @district = District.find(params[:id])

    if @district.update_attributes(params[:district])
      flash[:notice] = 'Området uppdaterades.'
      redirect_to(@district)
    else
      @school_types = SchoolType.order(:name)
      render action: "new"
    end
  end

  def destroy
    @district = District.find(params[:id])
    @district.destroy

    flash[:notice] = "Området togs bort."
    redirect_to(districts_url)
  end


  # Selects a district for a working session. This is used
  # by the select group fragment to initialize the selection
  # process by selecting a district.
  def select
    district = District.find params[:district_id]
    session[:group_selection] = { district_id: district.id }
  rescue
  ensure
    if request.xhr?
      render text: "", content_type: "text/plain"
    else
      redirect_to params[:return_to]
    end
  end

  protected
  
  # Sort by the name by default
  def sort_column_from_param(p)
    return "districts.name" if p.blank?

    case p.to_sym
    when :school_type then "school_types.name"
    else
      "districts.name"
    end
  end
end
