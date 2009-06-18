class CalendarController < ApplicationController

  layout "standard"
  
  def index

    @from = Date.today
    @to = @from.advance(:months => 2)
    
    @occasions = Occasion.all :include => { :event => :culture_provider },
      :conditions => [ "occasions.date between ? and ? and current_date between events.visible_from and events.visible_to", @from, @to ],
      :order => "occasions.date ASC, events.name ASC"

    @category_groups = CategoryGroup.all :order => "name ASC"
  end

end
