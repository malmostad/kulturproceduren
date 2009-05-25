class BookingController < ApplicationController
  require "pp"
  before_filter :authenticate
  layout "standard"

  def book
     @user = User.find_by_id(session[:current_user_id])
     @occasion = Occasion.find_by_id(params[:occasion_id])
     if ( @occasion.nil? )
       flash[:error] = "Ingen föreställning angiven"
       redirect_to :controller => "occasions"
       return
     end
     @groups = @user.groups
     pp @groups
     pp params

     if params[:what] == "book" then

       # Utför bokning och omdirigera till visa bokningar

       group = Group.find_by_id(params[:group_id])
       if ( group.nil?)
         flash[:error] = "Ingen grupp angiven"
         redirect_to :controller => "booking", :action => "book", :occasion_id => "#{params[:occasion_id]}"
         return
       end
       if ( ( params[:no_tickets].nil? ) or ( params[:no_tickets].to_i < 0 ) )
         flash[:error] = "Du måte ange antal biljetter du vill boka"
         redirect_to :controller => "booking", :action => "book", :occasion_id => "#{params[:occasion_id]}"
         return
       end
       if ( @occasion.event.ticket_state == Event::ALLOTED_GROUP )
         tickets = Ticket.find(:all, :conditions => "group_id = #{params[:group_id]} AND event_id = #{@occasion.event_id} AND state=#{Ticket::UNBOOKED}")
       elsif ( @occasion.event.ticket_state == Event::ALLOTED_DISTRICT )
         tickets = Ticket.find(:all, :conditions => "district_id = #{group.school.district.id} AND event_id = #{@occasion.event_id} AND state=#{Ticket::UNBOOKED}")
       elsif ( @occasion.event.ticket_state == Event::FREE_FOR_ALL )
         tickets = Ticket.find(:all, :conditions => "event_id = #{@occasion.event_id} AND state=#{Ticket::UNBOOKED}")
       else
         flash[:error] = "Inte bokningsbart evenemang"
         redirect_to :controller => "event", :action => "show"
         return
       end
       if params[:no_tickets].to_i > tickets.length
         flash[:error] = "Du kan bara boka #{tickets.length}"
         redirect_to :controller => "booking", :action => "book", :occasion_id => "#{params[:occasion_id]}"
         return
       else
         # Borde detta göras mha sql-update pga prestandaskäl?
         ntick = 0
         while (ntick < params[:no_tickets].to_i ) do
           tickets[ntick].occasion_id = params[:occasion_id]
           tickets[ntick].state = Ticket::BOOKED
           tickets[ntick].save
           ntick += 1
        end
         redirect_to :controller => "booking", :action => "show"
         return
       end
     else 
       ## Visa bokingsmöjligheter
       @bookable_tickets = Hash.new
       @groups.each do |g|
         if ( @occasion.event.ticket_state == Event::ALLOTED_GROUP )
           @bookable_tickets["#{g.id}"] = Ticket.find(:all, :conditions => "group_id = #{g.id} AND event_id = #{@occasion.event_id} AND state = #{Ticket::UNBOOKED}")
         elsif ( @occasion.event.ticket_state == Event::ALLOTED_DISTRICT )
           @bookable_tickets["#{g.id}"] = Ticket.find(:all, :conditions => "district_id = #{group.school.district.id} AND event_id = #{@occasion.event_id} AND state = #{Ticket::UNBOOKED}")
         elsif ( @occasion.event.ticket_state == Event::FREE_FOR_ALL )
           @bookable_tickets["#{g.id}"] = Ticket.find(:all, :conditions => "event_id = #{@occasion.event_id} and state = #{Ticket::UNBOOKED}")
         else
           flash[:error] = "Inte bokningsbart evenemang"
           redirect_to :controller => "event", :action => "show"
           return
         end
       end
       #pp @bookable_tickets
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

