# Controller for handling dispatching of incoming URLs. This is
# used when the application runs as a Proxy Portlet to get around
# the problem of linking directly into a specific page in the application.
class DispatchController < ApplicationController
  def index
    if ActionController::Base.relative_url_root
      redirect_to ActionController::Base.relative_url_root + params[:goto]
    else
      redirect_to params[:goto]
    end
  end
end
