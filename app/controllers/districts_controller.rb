# -*- encoding : utf-8 -*-
# Controller for managing districts
class DistrictsController < ApplicationController
  layout "admin"
  
  before_filter :authenticate
  before_filter :require_admin, :except => [ :select ]

  def index
    @districts = District.paginate :page => params[:page],
      :order => sort_order("name")
  end

  def show
    @district = District.find(params[:id])
  end

  def new
    @district = District.new
  end

  def edit
    @district = District.find(params[:id])
    render :action => "new"
  end

  def create
    @district = District.new(params[:district])

    if @district.save
      flash[:notice] = 'Stadsdelen skapades.'
      redirect_to(@district)
    else
      render :action => "new"
    end
  end

  def update
    @district = District.find(params[:id])

    if @district.update_attributes(params[:district])
      flash[:notice] = 'Stadsdelen uppdaterades.'
      redirect_to(@district)
    else
      render :action => "new"
    end
  end

  def destroy
    @district = District.find(params[:id])
    @district.destroy

    flash[:notice] = "Stadsdelen togs bort."
    redirect_to(districts_url)
  end


  # Selects a district for a working session. This is used
  # by the select group fragment to initialize the selection
  # process by selecting a district.
  def select
    district = District.find params[:district_id]
    session[:group_selection] = { :district_id => district.id }
  rescue
  ensure
    if request.xhr?
      render :text => "", :content_type => "text/plain"
    else
      redirect_to params[:return_to]
    end
  end

  protected
  
  # Sort by the name by default
  def sort_column_from_param(p)
    return "name" if p.blank?

    case p.to_sym
    when :elit_id then "elit_id"
    else
      "name"
    end
  end
end
