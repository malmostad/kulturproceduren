class AgeGroupsController < ApplicationController
  layout "standard"

  def edit
    @age_group = AgeGroup.find(params[:id])
    @group = @age_group.group
    render :template => "groups/show"
  end
  
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
    @age_group = AgeGroup.find(params[:id])
    group = @age_group.group
    @age_group.destroy

    redirect_to(group)
  end
end
