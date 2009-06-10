class GroupsController < ApplicationController
  layout "admin", :except => [ :options_list ]
  
  before_filter :authenticate, :except => [ :options_list ]
  before_filter :require_admin, :except => [ :options_list ]

  def index
    @groups = Group.all :order => "name ASC", :include => { :school => :district }
  end

  def options_list
    if params[:school_id]
      @groups = Group.all :order => "name ASC", :conditions => { :school_id => params[:school_id] }
    else
      @groups = Group.all :order => "name ASC"
    end
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
      flash[:notice] = 'Group was successfully updated.'
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

    flash[:notice] = "Skolan togs bort."
    redirect_to(school)
  end
end
