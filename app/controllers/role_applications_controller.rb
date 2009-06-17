class RoleApplicationsController < ApplicationController
  layout "standard"
  
  before_filter :authenticate
  before_filter :deny_admin, :only => [ :booker, :culture_worker, :create ]
  before_filter :require_admin, :only => [ :archive, :edit, :update ]
  
  def index
    if current_user.has_role? :admin
      @applications = RoleApplication.find :all,
        :conditions => [ "state = ?", RoleApplication::PENDING ],
        :order => "created_at ASC",
        :include => [ :user, :role, :culture_provider ]

      render :action => "admin_index", :layout => "admin"
    else
      @booker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:booker) }
      @culture_worker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:culture_worker) }

      @culture_providers = CultureProvider.find :all, :order => "name"
    end
  end

  def archive
    @applications = RoleApplication.find :all,
      :order => "updated_at DESC",
      :include => [ :user, :role, :culture_provider ]
  end
  
  def edit
    @application = RoleApplication.find params[:id]
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
      
      case @application.role.symbol_name
      when :booker
        @culture_worker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:culture_worker) }
        @booker_appl = @application
      when :culture_worker
        @booker_appl = RoleApplication.new { |ra| ra.role = Role.find_by_symbol(:booker) }
        @culture_worker_appl = @application
        @culture_worker_appl_error = true
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
      render :action => "edit"
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
