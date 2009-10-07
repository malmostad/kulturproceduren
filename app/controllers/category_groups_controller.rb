# Controller for managing category groups
class CategoryGroupsController < ApplicationController
  layout "admin"

  cache_sweeper :calendar_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :culture_provider_sweeper, :only => [ :create, :update, :destroy ]


  # Displays a list of all categories in the system as well as a
  # form for adding new category groups
  def index
    @category_groups = CategoryGroup.all
    @category_group = CategoryGroup.new
  end

  # Displays a form for editing the given category group in the listing
  # from the index action
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
      @category_groups = CategoryGroup.all
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
