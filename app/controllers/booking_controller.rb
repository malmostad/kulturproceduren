class BookingController < ApplicationController
  before_filter :authenticate
  layout "standard"

  def book
     @user = User.find_by_id(session[:current_user_id])
     @groups = @user.groups
     @occasion = Occasion.find_by_id(params[:occasion_id])
     @tickets = Hash.new
     @groups.each do |g|
       @tickets["#{g.id}"] = Ticket.find(:all, :conditions => "event_id=#{@occasion.event_id}  AND group_id=#{g.id}")
     end
  end

  def show
  end

end
