# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  protected

  def authenticate
    unless session[:current_user_id]

      session[:return_to] = request.path

      flash[:error] = "Du har inte behörighet att komma åt sidan. Var god logga in."
      redirect_to :controller => "login"

      return false
    end
  end


  def user_online?
    !session[:current_user_id].nil?
  end
  helper_method :user_online?

  def current_user
    @current_user ||= User.find(session[:current_user_id])
  end

  def current_user_role?(role)
    current_user.roles.include?(Role.find_by_name(role))
  end
  helper_method :current_user_role?

end
