class RoleApplicationsController < ApplicationController
  layout "standard"
  before_filter :authenticate
  before_filter :deny_admin, :only => [ :booker, :culture_worker, :create ]
  before_filter :deny_user, :only => [ :archive, :edit, :update ]
  
  def index
    if current_user.has_role? :admin
      @applications = RoleApplication.find :all,
        :conditions => [ "state = ?", RoleApplication::PENDING ],
        :order => "created_at ASC",
        :include => [ :user, :role, :culture_provider ]

      render :action => "admin_index"
    end
  end

  def archive
    @applications = RoleApplication.find :all,
      :order => "updated_at DESC",
      :include => [ :user, :role, :culture_provider ]
  end

  def booker
    @application = RoleApplication.new
    @application.role_id = Role.find_by_symbol(:booker).id
  end

  def culture_worker
    @application = RoleApplication.new
    @application.role_id = Role.find_by_symbol(:culture_worker).id

    @culture_providers = CultureProvider.find :all, :order => "name"
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
      redirect_to :controller => "account", :action => "index"
    else
      case @application.role.symbol_name
      when :booker
        render :action => "booker"
      when :culture_worker
        @culture_providers = CultureProvider.find :all, :order => "name"
        render :action => "culture_worker"
      end
    end
  end

  def update
    @application = RoleApplication.find(params[:id])

    if @application.update_attributes(params[:role_application])

      unless @application.user.roles.any? { |r| r.id == @application.role.id }
        @application.user.roles << @application.role
      end

      case @application.role.symbol_name
      when :culture_worker
        if @application.culture_provider
          @application.user.culture_providers << @application.culture_provider
        else
          cp = CultureProvider.new
          cp.name = @application.new_culture_provider_name
          cp.save
          @application.user.culture_providers << cp
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

  def deny_user
    unless current_user.has_role? :admin
      flash[:notice] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
    end
  end

end
