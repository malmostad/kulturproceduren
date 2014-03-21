# -*- encoding : utf-8 -*-
# Controller for managin login and logout
class LoginController < ApplicationController

  layout "standard"

  # Display a form for logging in
  def index
    session[:return_to] = params[:return_to] if params[:return_to]
  end

  # Authenticates the user
  def login
    if user_online?
      redirect_to root_url()
      return
    end

    u = authenticate_user()

    if u.nil?
      flash[:warning] = "Felaktigt användarnamn/lösenord"
      render :action => "index"
    else
      session[:current_user_id] = u.id
      flash[:notice] = "Du är nu inloggad"

      u.last_active = Time.zone.now
      u.save

      if !u.valid?
        flash[:warning] = "Kulturproceduren har uppdaterats med ytterligare fält i din profil. Var god uppdatera din profil."
        redirect_to edit_user_url(u)
      elsif u.roles.empty?
        flash[:warning] = "Du har för tillfället inga behörigheter i systemet. Var god ansök om behörigheter nedan."
        redirect_to role_applications_url()
      elsif session[:return_to]
        redirect_to session[:return_to]
        session[:return_to] = nil
      else
        redirect_to root_url()
      end
    end
  end

  # Logs out the user
  def logout
    if user_online?
      session[:current_user_id] = nil
      flash[:notice] = "Du är nu utloggad."
      redirect_to root_url()
    else
      redirect_to :action => "index"
    end
  end

  # Workaround for session problems when using the application as a proxy
  # portlet.
  #
  # When the first access to the application is via a portal, the session cookie
  # is not set on the client but rather in the portal. This is problematic when going
  # to a standalone application, because since the session cookie is not stored
  # on the client, access to the session from the portal will not be possible.
  #
  # In order to fix this, we provide a method that sends the cookie parameters for
  # the session cookie as JSON data, for use in an Ajax call that sets the cookie
  # on the client.
  def session_fix
    session_cookie = {
      :name => request.session_options[:key],
      :value => cookies[request.session_options[:key]],
      :options => {
        :path => request.session_options[:path],
        :domain => request.session_options[:domain],
        :secure => request.session_options[:secure]
      }
    }
    render :json => session_cookie.to_json
  end

  private

  def get_ldap
    ldap = KPLdapManager.new(
      APP_CONFIG[:ldap][:address],
      APP_CONFIG[:ldap][:port],
      APP_CONFIG[:ldap][:base_dn],
      APP_CONFIG[:ldap][:bind][:dn],
      APP_CONFIG[:ldap][:bind][:password]
    )
  end

  # Authenticates the user by first checking the LDAP, then the local user database.
  #
  # If the user is authenticated by the LDAP but does not have a local user profile,
  # a profile is automatically created.
  def authenticate_user
    if APP_CONFIG[:ldap]
      ldap = get_ldap()

      ldap_user = ldap.authenticate params[:user][:username], params[:user][:password]

      if ldap_user
        user = User.where(username: "#{APP_CONFIG[:ldap][:username_prefix]}#{params[:user][:username]}").first

        if user
          return user
        else
          ldap_user = ldap.get_user(params[:user][:username])

          user = User.new
          user.name                  = ldap_user[:name]
          user.email                 = ldap_user[:email]
          user.cellphone             = ldap_user[:cellphone]
          user.username              = "#{APP_CONFIG[:ldap][:username_prefix]}#{ldap_user[:username]}"
          user.password              = "ldap"
          user.password_confirmation = "ldap"
          user.districts             << District.first

          user.save!

          return user
        end
      else
        return params[:user] && User.authenticate(params[:user][:username], params[:user][:password])
      end
    else
      return params[:user] && User.authenticate(params[:user][:username], params[:user][:password])
    end
  end
end
