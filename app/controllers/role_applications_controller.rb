# Controller for managing role applications
class RoleApplicationsController < ApplicationController
  layout "application"
  
  before_filter :authenticate
  before_filter :deny_admin, only: [ :create ]
  before_filter :require_admin, only: [ :archive, :edit, :update ]
  
  # For administrators: displays a list of all incoming unanswered role applications.
  #
  # For regular users, displays forms for requesting roles as well as a list
  # of all the user's applications
  def index
    if current_user.has_role? :admin
      @applications = RoleApplication.includes(:user, :role, :culture_provider)
        .where("state = ?", RoleApplication::PENDING)
        .order(sort_order("created_at"))
        .paginate(page: params[:page])

      render action: "admin_index", layout: "admin"
    else
      @booker = Role.where("lower(name) = ?", "booker").first
      @culture_worker = Role.where("lower(name) = ?", "culture_worker").first
      @host = Role.where("lower(name) = ?",  "host").first

      @role_application = RoleApplication.new { |ra| ra.role = @booker }
      @culture_providers = CultureProvider.order("name")
    end
  end

  # Displays a list of all answered appliations
  def archive
    params[:d] ||= "down"
    @applications = RoleApplication.includes(:user, :role, :culture_provider)
      .order(sort_order("created_at"))
      .paginate(page: params[:page])
    render layout: "admin"
  end
  
  def edit
    @application = RoleApplication.find params[:id]

    if @application.state != RoleApplication::PENDING
      flash[:warning] = "Behörighetsansökan är redan besvarad"
      redirect_to action: "archive"
    else
      render layout: "admin"
    end
  end

  # Submits a role application from a user
  def create
    @role_application = RoleApplication.new(params[:role_application])
    @role_application.user = current_user
    @role_application.state = RoleApplication::PENDING

    if @role_application.save
      flash[:notice] = "Din ansökan har skickats till administratörerna."
      redirect_to current_user
    else
      @culture_providers = CultureProvider.order("name")

      @booker = Role.where("lower(name) = ?", "booker").first
      @culture_worker = Role.where("lower(name) = ?", "culture_worker").first
      @host = Role.where("lower(name) = ?",  "host").first

      render action: "index"
    end
  end

  # Answers a role application
  def update
    @application = RoleApplication.find(params[:id])

    if @application.update_attributes(params[:role_application])

      if @application.state == RoleApplication::ACCEPTED

        unless @application.user.roles.any? { |r| r.id == @application.role.id }
          @application.user.roles << @application.role
        end

        case @application.role.symbol_name
        when :culture_worker
          if @application.culture_provider
            @application.user.culture_providers << @application.culture_provider
          else
            @application.user.culture_providers << CultureProvider.create(name: @application.new_culture_provider_name)
          end
        end

      end

      flash[:notice] = 'Ansökan besvarades.'
      redirect_to action: "index"
    else
      render action: "edit", layout: "admin"
    end
  end
  
  protected

  # Sort by the creation date by default
  def sort_column_from_param(p)
    return "created_at" if p.blank?

    case p.to_sym
    when :role then "roles.name"
    when :user then "users.name"
    when :state then "state"
    when :updated_at then "updated_at"
    else
      "created_at"
    end
  end

  private

  # Denies access to admins. For use in <tt>before_filter</tt>.
  def deny_admin
    if current_user.has_role? :admin
      flash[:notice] = "Du har redan administratörsbehörigheter och kan därför inte ansöka om behörigheter."
      redirect_to action: "index"
    end
  end

end
