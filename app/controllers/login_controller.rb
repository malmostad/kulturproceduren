class LoginController < ApplicationController

  layout "standard"
  
  def index
  end

  def login
    if user_online?
      redirect_to :action => "index"
    end
    
    u = User.authenticate params[:user][:username], params[:user][:password]

    if u.nil?
      flash[:error] = "Invalid username or password"
      render :action => "index"
    else
      flash[:notice] = "Login successful"
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
      flash[:notice] = "Logout successful"
      redirect_to "/"
    else
      redirect_to :action => "index"
    end
  end

end
