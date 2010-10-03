# Controller for managing users.
class UsersController < ApplicationController
  layout :set_layout

  before_filter :authenticate,
    :except => [ :new, :create, :request_password_reset, :send_password_reset_confirmation, :reset_password ]
  before_filter :require_admin,
    :only => [ :grant, :revoke, :destroy, :add_culture_provider, :remove_culture_provider ]
  before_filter :load_user,
    :only => [ :show, :edit, :edit_password, :update, :update_password ]

  # Displays a list of users in the system.
  def index
    if current_user.has_role?(:admin)
      @users = User.paginate :page => params[:page],
        :order => sort_order("username")
    else
      redirect_to current_user
    end
  end

  # Displays a user's details. If the user is not an administrator,
  # the user's own details is always displayed.
  def show
  end

  # Grant roles to a user.
  def grant
    user = User.find(params[:id])
    role = Role.find_by_symbol(params[:role].to_sym)

    unless user.has_role?(role.symbol_name)
      user.roles << role
      flash[:notice] = "Användaren tilldelades rättigheter."
    end

    redirect_to user
  end
  
  # Revoke roles from a user.
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
    @districts = District.all :order => "name ASC"
  end

  def edit
    @districts = District.all :order => "name ASC"
  end

  # Displays a form for changing a user's password.
  def edit_password
    @user.reset_password
  end

  def create
    @user = User.new(params[:user])

    if APP_CONFIG[:ldap] && ldap_user_exists(params[:user][:username])
      @user.valid?
      @user.errors.add(:username,
                       :taken,
                       :default => "Användarnamnet är redan taget",
                       :value => params[:user][:username])
    elsif @user.save
      if user_online? && current_user.has_role?(:admin)
        flash[:notice] = 'Användaren skapades. Den kan nu logga in med användarnamn och lösenord.'
        redirect_to(@user)
      else
        flash[:notice] = 'Din användare har skapats. Du kan nu logga in med ditt användarnamn och lösenord.'
        redirect_to(:controller => "login")
      end

      return
    end

    @districts = District.all :order => "name ASC"
    @user.reset_password
    render :action => "new"
  end

  def update
    @user.name = params[:user][:name]
    @user.email = params[:user][:email]
    @user.cellphone = params[:user][:cellphone]
    @user.district_ids = params[:user][:district_ids]

    if @user.save
      flash[:notice] = 'Användaren uppdaterades.'
      redirect_to(@user)
    else
      @districts = District.all :order => "name ASC"
      render :action => "edit"
    end
  end

  # Updates a user's password. If the user is not an administrator, the user's
  # current password is required in order to change it.
  def update_password
    if !(user_online? && current_user.has_role?(:admin)) && !@user.authenticate(params[:current_password])
      flash[:warning] = "Felaktigt lösenord."
      redirect_to edit_password_user_url(@user)
      return
    elsif params[:user][:password].blank?
      flash[:warning] = "Lösenordet får inte vara tomt."
      redirect_to edit_password_user_url(@user)
      return
    elsif params[:user][:password] != params[:user][:password_confirmation]
      flash[:warning] = "Lösenordsbekräftelsen matchar inte."
      redirect_to edit_password_user_url(@user)
      return
    end

    @user.password = params[:user][:password]

    if @user.save
      flash[:notice] = "Lösenordet uppdaterades."
      redirect_to :action => "index"
    else
      flash[:warning] = "Ett fel uppstod när lösenordet uppdaterades."
      redirect_to edit_password_user_url(@user)
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy

    redirect_to(users_url)
  end

  # Associates a user with a culture provider.
  def add_culture_provider
    user = User.find(params[:id])
    culture_provider = CultureProvider.find params[:culture_provider_id]

    unless user.culture_providers.any? { |cp| cp.id == culture_provider.id }
      user.culture_providers << culture_provider
      flash[:notice] = "Användarens rättigheter uppdaterades."
    end

    redirect_to user
  end

  # Removes the association between a culture_provider and a user.
  def remove_culture_provider
    user = User.find(params[:id])
    culture_provider = CultureProvider.find params[:culture_provider_id]

    if user.culture_providers.any? { |cp| cp.id == culture_provider.id }
      user.culture_providers.delete culture_provider
      flash[:notice] = "Användarens rättigheter uppdaterades."
    end

    redirect_to user
  end


  # Displays a form for requesting a password reset for an account
  def request_password_reset
    @user = User.new
  end

  # Sends a confirmation email to the user requesting the password reset
  def send_password_reset_confirmation
    if !params[:user][:username].blank?
      users = User.find :all, :conditions => { :username => params[:user][:username] }
    elsif !params[:user][:email].blank?
      users = User.find :all, :conditions => { :email => params[:user][:email] }
    else
      flash[:warning] = "Du måste ange ett användarnamn eller en epostadress."
      redirect_to request_password_reset_users_url()
      return
    end
    
    if users.blank?
      flash[:warning] = "Användaren finns inte i systemet."
      redirect_to request_password_reset_users_url()
      return
    end

    begin
      users.each do |user|
        user.generate_request_key()
        user.save!

        UserMailer.deliver_password_reset_confirmation_email(user)
      end

      flash[:notice] = "Ett bekräftelsemeddelande har nu skickats till den epostadress som är angiven i användarkontot. Lösenordet återställs först efter att du har följt instruktionerna i meddelandet."
      redirect_to root_url()
    rescue
      flash[:error] = "Ett fel uppstod när förfrågan behandlades. Var god försök igen senare."
      redirect_to request_password_reset_users_url()
    end
  end

  # Resets a user's password
  def reset_password
    user = User.find params[:id]

    if params[:key] == user.request_key
      password = user.generate_new_password()
      UserMailer.deliver_password_reset_email(user, password)
      flash[:notice] = "Ditt nya lösenord har skickats till din epost."
      redirect_to :controller => "login", :action => "index"
    else
      flash[:warning] = "Felaktig förfrågan."
      redirect_to root_url()
    end
  end


  protected

  # Sort users by their username by default.
  def sort_column_from_param(p)
    return "username" if p.blank?

    case p.to_sym
    when :name then "name"
    when :cellphone then "cellphone"
    when :email then "email"
    else
      "username"
    end
  end


  private

  # Use the admin layout if the user is an administrator.
  def set_layout
    user_online? && current_user.has_role?(:admin) ? "admin" : "standard"
  end

  # Loads the requested user from the database.
  def load_user
    if current_user.has_role?(:admin)
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

  # Checks if a username exists in the LDAP.
  def ldap_user_exists(username)
    ldap = KPLdapManager.new APP_CONFIG[:ldap][:address],
      APP_CONFIG[:ldap][:port],
      APP_CONFIG[:ldap][:base_dn],
      APP_CONFIG[:ldap][:bind][:dn],
      APP_CONFIG[:ldap][:bind][:password]

    return !ldap.get_user(username).nil?
  end
end
