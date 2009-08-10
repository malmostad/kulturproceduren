class LoginController < ApplicationController

  layout "standard"

  def index
  end

  def login
    if user_online?
      redirect_to :action => "index"
    end

    u = authenticate_user()

    if u.nil?
      flash[:warning] = "Felaktigt användarnamn/lösenord"
      render :action => "index"
    else
      flash[:notice] = "Du är nu inloggad som #{CGI.escapeHTML(u.username)}"
      session[:current_user_id] = u.id

      if session[:return_to]
        redirect_to session[:return_to]
        session[:return_to] = nil
      else
        redirect_to "/"
      end
    end
  end

  def logout
    if user_online?
      session[:current_user_id] = nil
      flash[:notice] = "Du är nu utloggad."
      redirect_to "/"
    else
      redirect_to :action => "index"
    end
  end

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


  def authenticate_user
    ldap = KPLdapManager.new APP_CONFIG[:ldap][:address],
      APP_CONFIG[:ldap][:port],
      APP_CONFIG[:ldap][:base_dn],
      APP_CONFIG[:ldap][:bind][:dn],
      APP_CONFIG[:ldap][:bind][:password]

    ldap_user = ldap.authenticate params[:user][:username], params[:user][:password]

    if ldap_user
      user = User.find :first, :conditions => { :username => params[:user][:username] }

      if user
        return user
      else
        ldap_user = ldap.get_user(params[:user][:username])

        user = User.new do |u|
          u.name = ldap_user[:name]
          u.email = ldap_user[:email]
          u.cellphone = ldap_user[:cellphone]
          u.username = ldap_user[:username]
          u.password = "ldap"
        end

        user.save!

        return user
      end
    else
      return User.authenticate(params[:user][:username], params[:user][:password])
    end
  end

end
