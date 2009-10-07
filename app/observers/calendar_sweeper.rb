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

  def invalidate_cache
    expire_fragment %r{calendar/list/(events|occasions)/(not_)?bookable/\d+}
  end
end
