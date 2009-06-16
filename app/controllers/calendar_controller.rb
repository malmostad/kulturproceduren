class CalendarController < ApplicationController

  layout "standard"
  
  def index

    @from = Date.today
    @to = @from.advance(:months => 2)
    
    @occasions = Occasion.all :include => :event,
      :conditions => [ "occasions.date between ? and ? and current_date between events.visible_from and events.visible_to", @from, @to ],
      :order => "occasions.date ASC, events.name ASC"
  end

  def calendar

    if ! params[:month].nil?
      month = params[:month].to_i
      year  = params[:year].to_i
      @dispmonth = Date.new(year,month,1)
      if @dispmonth.nil?
        flash[:error] = "Felaktiga parametrar"
        redirect_to :controller => "calendar", action => "calendar"
        return
      end
    else
      @dispmonth = Date.today
    end

    @nextmonth = @dispmonth << -1
    @prevmonth = @dispmonth << 1
    @monthdays = dim(@dispmonth.month,@dispmonth.year)

    @occasions = Occasion.find(:all,
      :conditions => ["date BETWEEN '#{@dispmonth.year}-#{@dispmonth.month}-01' and '#{@dispmonth.year}-#{@dispmonth.month}-#{@monthdays}'"],
      :order => "date DESC")

    @oh = {}
    @occasions.each do |t|
      @oh[t.date] = t
    end
    @dispmonth_sday = Date.new(@dispmonth.year, @dispmonth.month, 1)
    @cal_sday = @dispmonth_sday - @dispmonth_sday.cwday
  end
  
  private

  def dim(m,y)
    d = 27
    d = d + 1 while Date.valid_civil?(y, m, d)
    d = d - 1
    return d
  end

end
