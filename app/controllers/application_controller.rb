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

      flash[:error] = "You are not authorized to access the requested page."
      redirect_to :controller => "login"

      return false
    end
  end

  def user_online?
    !session[:current_user_id].nil?
  end
  helper_method :user_online?

end
