# -*- encoding : utf-8 -*-
# Controller for handling dispatching of incoming URLs. This is
# used when the application runs as a Proxy Portlet to get around
# the problem of linking directly into a specific page in the application.
class DispatchController < ApplicationController

  # Redirects to the application path given in <tt>params[:goto]</tt>
  # or the root url if no path is given.
  def index
    if params[:goto]
      if ActionController::Base.relative_url_root && !params[:goto].start_with?(ActionController::Base.relative_url_root)
        redirect_to ActionController::Base.relative_url_root + params[:goto]
      else
        redirect_to params[:goto]
      end
    else
      redirect_to root_url()
    end
  end
end
