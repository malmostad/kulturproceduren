class CalendarController < ApplicationController

  before_filter :authenticate

  def index
  @message = session[:current_user_id]
  end

end
