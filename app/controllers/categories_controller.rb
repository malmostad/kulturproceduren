class CategoriesController < ApplicationController

  layout "admin"

  before_filter :authenticate
  before_filter :require_admin

  def index
    @categories = Category.all :include => :category_group,
      :order => "category_groups.name ASC, categories.name ASC"
    @category_groups = CategoryGroup.all
    
    @category = Category.new
  end

  def edit
    @categories = Category.all :include => :category_group
    @category_groups = CategoryGroup.all

    @category = Category.find params[:id]
    
    render :action => "index"
  end

  def create
    @category = Category.new(params[:category])

    if @category.save
      flash[:notice] = 'Kategorin skapades.'
      redirect_to :action => "index"
    else
      flash.now[:error] = 'Fel uppstod när kategorin skulle skapas.'
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
      flash.now[:error] = 'Fel uppstod när kategorin skulle uppdateras.'
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
