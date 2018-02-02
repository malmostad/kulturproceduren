# Sweeper for fragment caches concerning culture providers
class CultureProviderSweeper < ActionController::Caching::Sweeper
  observe Event, Occasion, CultureProvider, Category, CategoryGroup

  def after_save(record)
    invalidate_cache(record)
  end

  def after_destroy(record)
    invalidate_cache(record)
  end

  private

  # Invalidates a single culture provider's cache or all
  # culture providers' caches depending on the event that
  # caused the sweeping
  def invalidate_cache(record)
    case record
    when CultureProvider then invalidate_single(record)
    when Event then invalidate_single(record.culture_provider)
    when Occasion then invalidate_single(record.event.culture_provider)
    when Category, CategoryGroup then invalidate_all()
    end
  end

  # Removes the cache of a single culture provider
  def invalidate_single(culture_provider)
    ActionController::Base.new.expire_fragment "culture_providers/show/#{culture_provider.id}/upcoming_occasions/bookable"
    ActionController::Base.new.expire_fragment "culture_providers/show/#{culture_provider.id}/upcoming_occasions/not_bookable"
    ActionController::Base.new.expire_fragment "culture_providers/show/#{culture_provider.id}/standing_events"
    ActionController::Base.new.expire_fragment "culture_providers/show/#{culture_provider.id}/all_events"
    ActionController::Base.new.expire_fragment "culture_providers/show/#{culture_provider.id}/show_all"
  end

  # Removes the cache for all culture providers
  def invalidate_all
    ActionController::Base.new.expire_fragment %r{culture_providers/show/\d+/upcoming_occasions}
    ActionController::Base.new.expire_fragment %r{culture_providers/show/\d+/standing_events}
  end
end
