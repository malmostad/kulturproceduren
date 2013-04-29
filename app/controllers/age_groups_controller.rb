# Controller for managing age groups
class AgeGroupsController < ApplicationController
  layout "admin"

  before_filter :authenticate
  before_filter :require_admin

  # Renders the age group's group's view, since the age group administration
  # is done entirely within its group's view.
  def edit
    @age_group = AgeGroup.find(params[:id])
    @group = @age_group.group
    render :template => "groups/show"
  end
  
  # Any errors is rendered in the age group's group's view
  def create
    @age_group = AgeGroup.new(params[:age_group])

    if @age_group.save
      flash[:notice] = 'Åldersgruppen skapades.'
      redirect_to(@age_group.group)
    else
      @group = @age_group.group
      render :template => "groups/show"
    end
  end

  # Any errors is rendered in the age group's group's view
  def update
    @age_group = AgeGroup.find(params[:id])

    if @age_group.update_attributes(params[:age_group])
      flash[:notice] = 'Åldersgruppen uppdaterades.'
      redirect_to(@age_group.group)
    else
      @group = @age_group.group
      render :template => "groups/show"
    end
  end

  def destroy
    age_group = AgeGroup.find(params[:id])
    group = age_group.group
    age_group.destroy

    redirect_to(group)
  end
end
