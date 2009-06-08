class AdminController < ApplicationController
  layout "admin"

  before_filter :authenticate
  before_filter :require_admin
  
  def index
  end
end
