# Controller for displaying the welcoming occasion/event calendar for the user
class CalendarController < ApplicationController

  layout "application"

  # Displays a regular calendar for occasions/events without any search filter
  def index
    @age_categories = AgeCategory.order(sort_order: :asc).all
  end

  # Displays a regular calendar for occasions/events without any search filter
  def index_details
    session[:age_category] = params[:age_category] && !params[:age_category].blank? ? params[:age_category].to_i : session[:age_category] || -1
    @age_category = session[:age_category]

    unless fragment_exist?(list_cache_key())
      @category_groups = CategoryGroup.order "name ASC"
      @age_categories = AgeCategory.order(sort_order: :asc).all
      from_age, to_age, further_education = age_range()

      if events_calendar?
        if further_education == true then
          @events = Event.search_standing({ from_date: Date.today, from_age: from_age, to_age: to_age, further_education: true }, params[:page])
        else
          @events = Event.search_standing({ from_date: Date.today, from_age: from_age, to_age: to_age }, params[:page])
        end
      else
        if further_education == true then
          @occasions = Occasion.search({ from_date: Date.today, from_age: from_age, to_age: to_age, further_education: true }, params[:page])
        else
          @occasions = Occasion.search({ from_date: Date.today, from_age: from_age, to_age: to_age }, params[:page])
        end
      end
    end
  end

  # Displays a regular calendar for occasions/events with a search filter
  def filter
    session[:age_category] = params[:age_category] && !params[:age_category].blank? ? params[:age_category].to_i : session[:age_category] || -1
    @age_category = session[:age_category]
    # if (!calendar_filter[:from_age] || calendar_filter[:from_age] == -1) && (!calendar_filter[:to_age] || calendar_filter[:to_age] == -1) && @age_category != 0
    #   from_age, to_age = age_range()
    #   calendar_filter[:from_age] = from_age
    #   calendar_filter[:to_age] = to_age
    # end

    if events_calendar?
      @events = Event.search_standing(calendar_filter, params[:page])
    else
      @occasions = Occasion.search(calendar_filter, params[:page])
    end

    @category_groups = CategoryGroup.order "name ASC"
    @age_categories = AgeCategory.order(from_age: :asc).all
  end

  # Stores the search parameters from the calendar filter in the session
  def apply_filter
    if params[:clear_filter]
      session[:calendar_filter] = { from_date: Date.today }
    elsif params[:filter]
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
    redirect_to action: "filter", list: calendar_list
  end

  # Removes all search parameters from the session
  def clear_filter
    session[:calendar_filter] = { from_date: Date.today }
    redirect_to action: "filter", list: calendar_list
  end


  protected

  # Convenience accessor for the calendar filter in the session
  def calendar_filter
    session[:calendar_filter] ||= { from_date: Date.today }
    session[:calendar_filter]
  end
  helper_method :calendar_filter


  # Convenience accessor for the list cache key
  def list_cache_key
    age_category = session[:age_category] || 0
    "calendar/list/#{calendar_list}/#{age_category}/#{user_online? && current_user.can_book? ? "" : "not_" }bookable/#{params[:page] || 1}"
  end
  helper_method :list_cache_key

  def occasions_calendar?
    calendar_list == :occasions
  end
  helper_method :occasions_calendar?
  def events_calendar?
    calendar_list == :events
  end
  helper_method :events_calendar?

  # Sets the list to used based on the incoming list parameter
  def calendar_list
    params[:list] == 'events' ? :events : :occasions
  end

  def age_range
    from_age = -1
    to_age = 100
    further_education = false

    if session[:age_category] && session[:age_category] != 0
      age_category = AgeCategory.find_by_id(session[:age_category])
      if age_category
        from_age = age_category.from_age
        to_age = age_category.to_age
        further_education = age_category.further_education
      end
    end

    return from_age, to_age, further_education
  end

  helper_method :calendar_list

  private

  # Parses a date from a string, returning nil if the date is not of the correct format
  def parse_date(date_str)
    if date_str =~ /^\d{4}-\d{2}-\d{2}$/
      return Date.parse(date_str)
    else
      return nil
    end
  end

end
