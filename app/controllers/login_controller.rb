# Controller for managin login and logout
class LoginController < ApplicationController

  layout "application"

  # Display a form for logging in
  def index
    if user_online?
      redirect_to root_url()
      return
    end

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
      render action: "index"
    else
      session[:current_user_id] = u.id
      flash[:notice] = "Du är nu inloggad"

      u.last_active = Time.zone.now
      u.save

      if u.roles.empty?
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
      redirect_to action: "index"
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
      name: request.session_options[:key],
      value: cookies[request.session_options[:key]],
      options: {
        path: request.session_options[:path],
        domain: request.session_options[:domain],
        secure: request.session_options[:secure]
      }
    }
    render json: session_cookie.to_json
  end

  private

  def authenticate_user
    return params[:user] && User.authenticate(params[:user][:username], params[:user][:password])
  end
end
