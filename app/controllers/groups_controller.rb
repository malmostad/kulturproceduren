class GroupsController < ApplicationController
  layout "admin"
  
  def index
    @groups = Group.all :order => "name ASC"
  end

  def show
    @group = Group.find(params[:id])
    @age_group = AgeGroup.new { |ag| ag.group_id = @group.id }
  end

  def new
    @group = Group.new
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
    @group.destroy

    redirect_to(groups_url)
  end
end
