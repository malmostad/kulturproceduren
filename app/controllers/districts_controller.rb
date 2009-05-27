class DistrictsController < ApplicationController
  layout "admin"
  
  def index
    @districts = District.all
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

    redirect_to(districts_url)
  end
end
