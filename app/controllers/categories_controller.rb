# Controller for managing categories
class CategoriesController < ApplicationController

  layout "admin"

  before_filter :authenticate
  before_filter :require_admin

  cache_sweeper :calendar_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :culture_provider_sweeper, :only => [ :create, :update, :destroy ]


  # Displays a list of all categories currently in the system, as well
  # as a form for adding new categories
  def index
    @categories = Category.all :include => :category_group,
      :order => "category_groups.name ASC, categories.name ASC"
    @category_groups = CategoryGroup.all
    
    @category = Category.new
    @category.category_group_id = session[:selected_category_group] if session[:selected_category_group]
  end

  # Displays a form for editing the given category instead of
  # the new category form in the index action.
  def edit
    @categories = Category.all :include => :category_group
    @category_groups = CategoryGroup.all

    @category = Category.find params[:id]
    
    render :action => "index"
  end

  def create
    @category = Category.new(params[:category])

    session[:selected_category_group] = @category.category_group_id

    if @category.save
      flash[:notice] = 'Kategorin skapades.'
      redirect_to :action => "index"
    else
      @categories = Category.all :include => :category_group
      @category_groups = CategoryGroup.all
      render :action => "index"
    end
  end

  def update
    @category = Category.find(params[:id])

    if @category.update_attributes(params[:category])
      flash[:notice] = 'Kategorin uppdaterades.'
      redirect_to :action => "index"
    else
      @categories = Category.all :include => :category_group
      @category_groups = CategoryGroup.all
      render :action => "index"
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy

    flash[:notice] = 'Kategorin togs bort.'
    redirect_to :action => "index"
  end
end
