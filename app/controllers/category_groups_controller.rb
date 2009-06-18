class CategoryGroupsController < ApplicationController
  layout "admin"

  def index
    @category_groups = CategoryGroup.all
    @category_group = CategoryGroup.new
  end

  def edit
    @category_groups = CategoryGroup.all
    @category_group = CategoryGroup.find params[:id]

    render :action => "index"
  end

  def create
    @category_group = CategoryGroup.new(params[:category_group])

    if @category_group.save
      flash[:notice] = 'Kategorigruppen skapades.'
      redirect_to :action => "index"
    else
      @category_groups = CategoryGroup.all
      render :action => "index"
    end
  end

  def update
    @category_group = CategoryGroup.find(params[:id])

    if @category_group.update_attributes(params[:category_group])
      flash[:notice] = 'Kategorigruppen uppdaterades.'
      redirect_to :action => "index"
    else
      render :action => "index"
    end
  end

  def destroy
    @category_group = CategoryGroup.find(params[:id])
    @category_group.destroy

    flash[:notice] = 'Kategorigruppen togs bort.'
    redirect_to :action => "index"
  end

end
