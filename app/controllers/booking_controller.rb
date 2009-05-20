class BookingController < ApplicationController
  require "pp"
  before_filter :authenticate
  layout "standard"

  def book
     @user = User.find_by_id(session[:current_user_id])
     @occasion = Occasion.find_by_id(params[:occasion_id])
     pp params
     if params[:what] == "book" then
       tickets = Ticket.find(:all, :conditions => "group_id = #{params[:group_id]} AND event_id = #{@occasion.event_id}")
       # Borde detta göras mha sql-update pga prestandaskäl?
       tickets.each do |t|
         t.occasion_id = params[:occasion_id]
         t.state = BOOKED
         t.save
       end
       redirect_to :controller => "booking", :action => "show"
     else
       @groups = @user.groups
       @bookable_tickets = Hash.new
       @groups.each do |g|
         @bookable_tickets["#{g.id}"] = Ticket.find(:all, :conditions => "event_id=#{@occasion.event_id}  AND group_id=#{g.id}")
       end
     end
  end

  def show
     @user = User.find_by_id(session[:current_user_id])
     @groups = @user.groups
     @occasions_by_group = Hash.new
     @groups.each do |g|
       @occasions_by_group["#{g.id}"] = Hash.new
       tickets = Ticket.find(:all, :conditions => "group_id=#{g.id} and occasion_id is not null")
       tickets.each do |t|
         if @occasions_by_group["#{g.id}"]["#{t.occasion_id}"].nil? then
           @occasions_by_group["#{g.id}"]["#{t.occasion_id}"] = 1
         else
           @occasions_by_group["#{g.id}"]["#{t.occasion_id}"] += 1
         end
       end
     end
     pp @occasions_by_group
  end
end

