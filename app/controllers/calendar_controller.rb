class CalendarController < ApplicationController

  layout "standard"
  
  def index

    @from = Date.today
    @to = @from.advance(:months => 2)
    
    @occasions = Occasion.all :include => :event,
      :conditions => [ "occasions.date between ? and ? and events.show_date <= ?", @from, @to, Date.today ],
      :order => "occasions.date ASC, events.name ASC"
  end

  def calendar
    if ! params[:month].nil?
      @dispmonth = params[:month].to_i
    else
      @dispmonth = Date.today.month
    end

    if ! params[:year].nil?
      @dispyear = params[:year].to_i
    else
      @dispyear = Date.today.year
    end
    
    @monthdays = dim(@dispmonth, @dispyear)

    @occasions = Occasion.find(:all,
      :conditions => ["date BETWEEN '#{@dispyear}-#{@dispmonth}-01' and '#{@dispyear}-#{@dispmonth}-#{@monthdays}'"],
      :order => "date DESC")

    @oh = {}
    @occasions.each do |t|
      @oh[t.date] = t
    end

    @dispmonth_sday = Date.new(@dispyear, @dispmonth, 1)

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
