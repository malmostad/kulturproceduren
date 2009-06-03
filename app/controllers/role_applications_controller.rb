class RoleApplicationsController < ApplicationController
  layout "standard"
  before_filter :authenticate
  
  def index
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
  end

end
