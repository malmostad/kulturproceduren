class CalendarController < ApplicationController

  layout "standard"

  before_filter :set_list
  
  def index
    @category_groups = CategoryGroup.all :order => "name ASC"
    if @calendar_list == :events
      @events = Event.search_standing({ :from_date => Date.today }, params[:page])
    else
      @occasions = Occasion.search({ :from_date => Date.today }, params[:page])
    end
  end

  def filter
    if @calendar_list == :events
      @events = Event.search_standing(calendar_filter, params[:page])
    else
      @occasions = Occasion.search(calendar_filter, params[:page])
    end
    @category_groups = CategoryGroup.all :order => "name ASC"
  end

  def apply_filter
    if params[:clear_filter]
      session[:calendar_filter] = { :from_date => Date.today }
    else
      calendar_filter[:free_text] = params[:filter][:free_text]

      calendar_filter[:from_age] = (params[:filter][:from_age] || -1).to_i
      calendar_filter[:to_age] = (params[:filter][:to_age] || -1).to_i
      calendar_filter[:further_education] = params[:filter][:further_education].to_i == 1

      calendar_filter[:from_date] = parse_date(params[:filter][:from_date])
      calendar_filter[:to_date] = parse_date(params[:filter][:to_date])

      calendar_filter[:date_span] = case params[:filter][:date_span]
                                    when "day" then :day
                                    when "week" then :week
                                    when "month" then :month
                                    when "date" then :date
                                    else
                                      :unbounded
                                    end

      categories = params[:filter][:categories] || []
      calendar_filter[:categories] = categories.map{ |i| i.to_i }.select { |i| i != -1 }

    end
    redirect_to :action => "filter", :list => @calendar_list
  end

  def clear_filter
    session[:calendar_filter] = { :from_date => Date.today }
    redirect_to :action => "filter", :list => @calendar_list
  end


  protected

  def calendar_filter
    session[:calendar_filter] ||= { :from_date => Date.today }
    session[:calendar_filter]
  end
  helper_method :calendar_filter


  private

  def set_list
    @calendar_list = params[:list] == 'events' ? :events : :occasions
  end

  def parse_date(date_str)
    if date_str =~ /^\d{4}-\d{2}-\d{2}$/
      return Date.parse(date_str)
    else
      return nil
    end
  end

end
