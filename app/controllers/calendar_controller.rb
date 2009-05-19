class CalendarController < ApplicationController

  before_filter :authenticate
  layout "standard"
  
  def dim(m,y)
    d = 27
    d = d + 1 while Date.valid_civil?(y, m, d)
    d = d -1
    return d
  end

  
  def index

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
    @monthdays = dim(@dispmonth,@dispyear)

    @occasions = Occasion.find(:all, :conditions => ["date BETWEEN '#{@dispyear}-#{@dispmonth}-01' and '#{@dispyear}-#{@dispmonth}-#{@monthdays}'"], :order => "date DESC")
    @oh = Hash.new
    @occasions.each do |t|
      @oh[t.date] = t
    end
    
    @dispmonth_sday = Date.new(@dispyear,@dispmonth,1)

    @cal_sday = @dispmonth_sday - @dispmonth_sday.cwday
    
  end

end
