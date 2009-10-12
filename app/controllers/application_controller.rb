# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  protected

  # Loads the appropriate data for the group selection fragment
  #
  # If occasion is given, the data is restricted to districts/schools/groups
  # that have tickets on the given occasion
  def load_group_selection_collections(occasion = nil)
    session[:group_selection] ||= {}

    gsc = {
      :districts => District.find(:all, :order => "name")
    }

    if session[:group_selection][:district_id]
      gsc[:schools] = School.find(
        :all,
        :order => "name",
        :conditions => { :district_id => session[:group_selection][:district_id] })
    end

    if session[:group_selection][:school_id]
      gsc[:groups] = Group.find(
        :all,
        :order => "name",
        :conditions => { :school_id => session[:group_selection][:school_id] })
    end

    if occasion
      @group_selection_collections = {}

      gsc.each_pair do |key, coll|
        @group_selection_collections[key] = coll.select do |i|
          i.available_tickets_by_occasion(occasion) > 0
        end
      end
    else
      @group_selection_collections = gsc
    end
  end

  # Method for getting the SQL sort order from paging parameters
  def sort_order(default)
    "#{sort_column_from_param(params[:c] || default)} #{params[:d] == 'down' ? 'DESC' : 'ASC'}"
  end
  helper_method :sort_order

  # Override in subclass to secure column sorting
  def sort_column_from_param(p)
    p
  end

  # Ensures that the user is authenticated, used as a +before_filter+
  def authenticate
    unless session[:current_user_id]

      session[:return_to] = request.parameters
      flash[:error] = "Du har inte behörighet att komma åt sidan. Var god logga in."
      redirect_to :controller => "login"
      return false
    end
  end

  # Ensures that the user is an administrator, used as a +before_filter+
  def require_admin
    unless current_user.has_role? :admin
      flash[:notice] = "Du har inte behörighet att komma åt sidan."
      redirect_to :action => "index"
    end
  end


  # Helper method for checking whether the current user is logged in or not.
  def user_online?
    !session[:current_user_id].nil?
  end
  helper_method :user_online?

  # Accessor method for getting the current user.
  def current_user
    @current_user ||= User.find(session[:current_user_id])
  end
  helper_method :current_user


  def occasion_list_cache_key(event)
    online = user_online?
    user = online ? current_user : nil
    online_prefix = online ? "" : "not_"
    bookable_prefix = online && user.can_book? ? "" : "not_"
    administratable_prefix = online && user.can_administrate?(event.culture_provider) ? "" : "not_"
    reportable_prefix = online && (user.has_role?(:admin) || user.has_role?(:host)) ? "" : "not_"

    "events/show/#{event.id}/occasion_list/#{online_prefix}online/#{bookable_prefix}bookable/#{administratable_prefix}administratable/#{reportable_prefix}reportable"
  end
  helper_method :occasion_list_cache_key
end
