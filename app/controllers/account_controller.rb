class AccountController < ApplicationController
  layout "standard"

  before_filter :authenticate, :only => [:update, :edit_password, :update_password]
  
  def index
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    if @user.save
      flash[:notice] = 'Din användare har skapats. Du kan nu logga in med ditt användarnamn och lösenord.'
      redirect_to(:controller => "login")
    else
      @user.reset_password
      render :action => "new"
    end
  end

  def update
    current_user.name = params[:user][:name]
    current_user.email = params[:user][:email]
    current_user.mobil_nr = params[:user][:mobil_nr]

    if current_user.save
      flash[:notice] = "Dina personuppgifter har uppdaterats."
      redirect_to :action => "index"
    else
      render :action => "index"
    end
  end

  def edit_password
    @user = User.new
  end

  def update_password
    if !current_user.authenticate(params[:current_password])
      flash[:error] = "Felaktigt lösenord."
      redirect_to :action => "edit_password"
      return
    elsif params[:user][:password].length <= 0
      flash[:error] = "Lösenordet får inte vara tomt."
      redirect_to :action => "edit_password"
      return
    elsif params[:user][:password] != params[:user][:password_confirmation]
      flash[:error] = "Lösenordsbekräftelsen matchar inte."
      redirect_to :action => "edit_password"
      return
    end

    current_user.password = params[:user][:password]

    if current_user.save
      flash[:notice] = "Ditt lösenord har uppdaterats."
      redirect_to :action => "index"
    else
      @user = current_user
      @user.reset_password
      render :action => "edit_password"
    end
  end

end
