class CalenderController < ApplicationController
  
  def index
    if user_online?
      @message = session[:current_user_id]
    else
      redirect_to :controller => 'login'
    end

  end

end
