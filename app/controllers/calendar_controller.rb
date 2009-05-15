class CalendarController < ApplicationController

  before_filter :authenticate

  def index
    @occasions = Occasion.find(:all, :order => "date DESC")
  end

end
