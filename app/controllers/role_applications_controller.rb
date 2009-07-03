class RoleApplicationsController < ApplicationController
  layout "standard"
  
  before_filter :authenticate
  before_filter :deny_admin, :only => [ :create ]
  before_filter :require_admin, :only => [ :archive, :edit, :update ]
  
  def index
    if current_user.has_role? :admin
      @applications = RoleApplication.paginate :page => params[:page],
        :conditions => [ "state = ?", RoleApplication::PENDING ],
        :order => sort_order("created_at"),
        :include => [ :user, :role, :culture_provider ]

      render :action => "admin_index", :layout => "admin"
    else

      @booker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:booker) }
      @culture_worker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:culture_worker) }
      @host_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:host) }

      @culture_providers = CultureProvider.find :all, :order => "name"
      
    end
  end

  def archive
    params[:d] ||= "down"

    @applications = RoleApplication.paginate :page => params[:page],
      :order => sort_order("created_at"),
      :include => [ :user, :role, :culture_provider ]

    render :layout => "admin"
  end
  
  def edit
    @application = RoleApplication.find params[:id]
    render :layout => "admin"
  end

  def create

    @application = RoleApplication.new(params[:role_application])
    @application.user = current_user
    @application.state = RoleApplication::PENDING

    if @application.save
      flash[:notice] = "Din ansökan har skickats till administratörerna."
      redirect_to current_user
    else
      @culture_providers = CultureProvider.find :all, :order => "name"

      @booker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:booker) }
      @culture_worker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:culture_worker) }
      @host_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:host) }

      @application_type = @application.role.symbol_name
      
      case @application_type
      when :booker
        @booker_appl = @application
      when :culture_worker
        @culture_worker_appl = @application
      when :host
        @host_appl = @application
      end

      render :action => "index"
    end
  end

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
            @application.user.culture_providers << CultureProvider.create(:name => @application.new_culture_provider_name)
          end
        end

      end

      flash[:notice] = 'Ansökan besvarades.'
      redirect_to :action => "index"
    else
      render :action => "edit", :layout => "admin"
    end
  end
  
  protected

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

  def deny_admin
    if current_user.has_role? :admin
      flash[:notice] = "Du har redan administratörsbehörigheter och kan därför inte ansöka om behörigheter."
      redirect_to :action => "index"
    end
  end

end
