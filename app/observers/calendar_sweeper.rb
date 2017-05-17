# Sweeper for fragment caching involving the calendar
class CalendarSweeper < ActionController::Caching::Sweeper

  observe Event, Occasion, CultureProvider, Category, CategoryGroup

  def after_save(record)
    invalidate_cache()
  end

  def after_destroy(record)
    invalidate_cache()
  end

  def after_bookings
    invalidate_cache()
  end

  private

  # Removes all cached fragments for the calendar
  def invalidate_cache
    ActionController::Base.new.expire_fragment %r{calendar/list/\d+/(events|occasions)/(not_)?bookable/\d+}
  end
end
