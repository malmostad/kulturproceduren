class CalendarController < ApplicationController

  layout "standard"
  
  def index
    @occasions = Occasion.search({ :from_date => Date.today }, params[:page])
    @category_groups = CategoryGroup.all :order => "name ASC"
  end

  def filter
    @occasions = Occasion.search calendar_filter, params[:page]
    @category_groups = CategoryGroup.all :order => "name ASC"
  end

  def apply_filter
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

    redirect_to :action => "filter"
  end

  def clear_filter
    session[:calendar_filter] = { :from_date => Date.today }
    redirect_to :action => "filter"
  end


  protected

  def calendar_filter
    session[:calendar_filter] ||= { :from_date => Date.today }
    session[:calendar_filter]
  end
  helper_method :calendar_filter


  private

  def parse_date(date_str)
    if date_str =~ /^\d{4}-\d{2}-\d{2}$/
      return Date.parse(date_str)
    else
      return nil
    end
  end

end
