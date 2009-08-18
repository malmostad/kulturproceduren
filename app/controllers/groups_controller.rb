class GroupsController < ApplicationController
  layout "admin", :except => [ :options_list ]
  
  before_filter :authenticate, :except => [ :options_list, :select ]
  before_filter :require_admin, :except => [ :options_list, :select ]

  def index
    @groups = Group.paginate :page => params[:page],
      :order => sort_order("name"),
      :include => { :school => :district }
  end

  def show
    @group = Group.find(params[:id])
    @age_group = AgeGroup.new { |ag| ag.group_id = @group.id }
  end

  def new
    @group = Group.new
    @group.school_id = params[:school_id] if params[:school_id]
    
    @schools = School.all :order => "name ASC"
  end

  def edit
    @group = Group.find(params[:id])
    @schools = School.all :order => "name ASC"
    render :action => "new"
  end

  def create
    @group = Group.new(params[:group])

    if @group.save
      flash[:notice] = 'Gruppen skapades.'
      redirect_to(@group)
    else
      @schools = School.all :order => "name ASC"
      render :action => "new"
    end
  end

  def update
    @group = Group.find(params[:id])

    if @group.update_attributes(params[:group])
      flash[:notice] = 'Gruppen uppdaterades.'
      redirect_to(@group)
    else
      @schools = School.all :order => "name ASC"
      render :action => "new"
    end
  end

  def destroy
    @group = Group.find(params[:id])
    school = @group.school
    @group.destroy

    flash[:notice] = "Gruppen togs bort."
    redirect_to(school)
  end


  def select
    session[:group_selection][:group_id] = params[:group_id].to_i

    if request.xhr?
      render :text => "", :content_type => "text/plain"
    else
      redirect_to params[:return_to]
    end
  end

  def options_list
    conditions = {}

    school_id = params[:school_id].to_i
    occasion_id = params[:occasion_id].to_i

    if (params[:school_id] && school_id <= 0) || (params[:occasion_id] && occasion_id <= 0)
      render :text => "", :content_type => 'text/plain', :status => 404
      return
    end

    if school_id > 0
      conditions[:school_id] = school_id
      session[:group_selection] = { :district_id => session[:group_selection][:district_id] }
      session[:group_selection][:school_id] = school_id
    end

    if occasion_id > 0
      @occasion = Occasion.find params[:occasion_id]
      @groups = Group.find(:all, :conditions => conditions).select { |g|
        g.ntickets_by_occasion(@occasion) > 0
      }
    else
      @groups = Group.all :order => "name ASC", :conditions => conditions
    end

    render :action => "options_list", :content_type => 'text/plain'
  rescue
    render :text => "", :content_type => 'text/plain', :status => 404
  end

  private

  def sort_column_from_param(p)
    return "name" if p.blank?

    case p.to_sym
    when :district then "districts.name"
    when :school then "schools.name"
    when :elit_id then "elit_id"
    else
      "name"
    end
  end
end
