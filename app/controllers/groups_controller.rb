# Controller for managing groups
class GroupsController < ApplicationController
  layout "application", except: [ :options_list ]
  
  before_filter :authenticate, except: [ :options_list, :select ]
  before_filter :require_admin, except: [ :options_list, :select ]

  def index
    if params[:filter] && params[:filter] == :external.to_s
      @groups = Group.includes(school: :district).where.not(extens_id: nil).order(name: :asc).paginate(page: params[:page])
    elsif params[:filter] && params[:filter] == :manual.to_s
      @groups = Group.includes(school: :district).where(extens_id: nil).order(name: :asc).paginate(page: params[:page])
    else
      @groups = Group.includes(school: :district).order(name: :asc).paginate(page: params[:page])
    end
  end

  def show
    @group = Group.find(params[:id])
    @age_group = AgeGroup.new { |ag| ag.group_id = @group.id }
    @schools = School.order("name ASC")
  end

  def history
    @group = Group.find(params[:id])
  end

  def new
    @group = Group.new
    @group.school_id = params[:school_id] if params[:school_id]
    
    @schools = School.order("name ASC")
  end

  def create
    @group = Group.new(params[:group])

    if @group.save
      flash[:notice] = 'Gruppen skapades.'
      redirect_to(@group)
    else
      @schools = School.order("name ASC")
      render action: "new"
    end
  end

  def update
    @group = Group.find(params[:id])

    if @group.update_attributes(params[:group])
      flash[:notice] = 'Gruppen uppdaterades.'
      redirect_to(@group)
    else
      @schools = School.order("name ASC")
      @age_group = AgeGroup.new { |ag| ag.group_id = @group.id }
      render action: "show"
    end
  end

  def move_first_in_priority
    group = Group.find(params[:id])
    group.move_first_in_prio
    redirect_to params[:return_to] || group_url()
  end

  def move_last_in_priority
    group = Group.find(params[:id])
    group.move_last_in_prio
    redirect_to params[:return_to] || group_url()
  end

  def destroy
    @group = Group.find(params[:id])
    school = @group.school
    @group.destroy

    flash[:notice] = "Gruppen togs bort."
    redirect_to(school)
  end


  # Selects a group for the working session. Used by the select group
  # fragment.
  def select
    group = Group.includes(:school).find(params[:group_id])
    session[:group_selection] = {
      district_id: group.school.district_id,
      school_name: group.school.name,
      school_id: group.school.id,
      group_id: group.id
    }
  rescue
  ensure
    if request.xhr?
      render text: "", content_type: "text/plain"
    else
      redirect_to params[:return_to]
    end
  end

  # Renders HTML select options as a fragment for use in Ajax calls.
  def options_list
    conditions = {}

    school = if !params[:school_id].blank?
               School.find params[:school_id]
             elsif !params[:school_name].blank?
               School.active.name_search(params[:school_name]).first!
             end

    if school
      conditions[:school_id] = school.id

      if params[:do_not_update_session].blank? or params[:do_not_update_session] == 'false'
        session[:group_selection] = {
            district_id: school.district_id,
            school_id: school.id,
            school_name: school.name
        }
      end
    end

    if params[:occasion_id]
      @occasion = Occasion.find params[:occasion_id]
      @groups = Group.where(conditions).order(name: :asc).to_a.select { |g|
        g.available_tickets_by_occasion(@occasion) > 0  #Bug ??
      }
    else
      @groups = Group.where(conditions).order(name: :asc)
    end

    render action: "options_list", content_type: 'text/plain', layout: false
  rescue
    render text: "", content_type: 'text/plain', status: 404, layout: false
  end

  private

  # Sort by the name by default
  def sort_column_from_param(p)
    return "name" if p.blank?

    case p.to_sym
    when :district then "districts.name"
    when :school then "schools.name"
    when :elit_id then "elit_id"
    when :active then "active"
    when :priority then "priority"
    else
      "name"
    end
  end
end
