class UsersController < ApplicationController
  layout :set_layout

  before_filter :authenticate, :except => [ :new, :create ]
  before_filter :require_admin, :only => [ :grant, :revoke, :destroy ]
  before_filter :load_user, :only => [ :show, :edit, :edit_password, :update, :update_password ]

  def index
    if current_user.has_role?(:admin)
      @users = User.all
    else
      redirect_to current_user
    end
  end

  def show
  end

  def grant
    user = User.find(params[:id])
    role = Role.find_by_symbol(params[:role].to_sym)

    unless user.has_role?(role.symbol_name)
      user.roles << role
      flash[:notice] = "Användaren tilldelades rättigheter."
    end

    redirect_to user
  end
  
  def revoke
    user = User.find(params[:id])
    role = Role.find_by_symbol(params[:role].to_sym)

    if user.has_role?(role.symbol_name)
      user.roles.delete role
      flash[:notice] = "Användarens rättigheter återkallades."
    end
    
    redirect_to user
  end

  def new
    @user = User.new
  end

  def edit
  end

  def edit_password
    @user.reset_password
  end

  def create
    @user = User.new(params[:user])

    if @user.save
      if user_online? && current_user.has_role?(:admin)
        flash[:notice] = 'Användaren skapades. Den kan nu logga användarnamn och lösenord.'
        redirect_to(@user)
      else
        flash[:notice] = 'Din användare har skapats. Du kan nu logga in med ditt användarnamn och lösenord.'
        redirect_to(:controller => "login")
      end
    else
      @user.reset_password
      render :action => "new"
    end
  end

  def update
    @user.name = params[:user][:name]
    @user.email = params[:user][:email]
    @user.mobil_nr = params[:user][:mobil_nr]
    
    if @user.save
      flash[:notice] = 'Användaren uppdaterades.'
      redirect_to(@user)
    else
      render :action => "edit"
    end
  end

  def update_password
    if !(user_online? && current_user.has_role?(:admin)) && !@user.authenticate(params[:current_password])
      flash[:error] = "Felaktigt lösenord."
      redirect_to edit_password_user_url(@user)
      return
    elsif params[:user][:password].blank?
      flash[:error] = "Lösenordet får inte vara tomt."
      redirect_to edit_password_user_url(@user)
      return
    elsif params[:user][:password] != params[:user][:password_confirmation]
      flash[:error] = "Lösenordsbekräftelsen matchar inte."
      redirect_to edit_password_user_url(@user)
      return
    end

    @user.password = params[:user][:password]

    if @user.save
      flash[:notice] = "Lösenordet uppdaterades."
      redirect_to :action => "index"
    else
      flash[:error] = "Ett fel uppstod när lösenordet uppdaterades."
      redirect_to edit_password_user_url(@user)
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy

    redirect_to(users_url)
  end

  private

  def set_layout
    user_online? && current_user.has_role?(:admin) ? "admin" : "standard"
  end

  def load_user
    if current_user.has_role?(:admin)
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end
end
