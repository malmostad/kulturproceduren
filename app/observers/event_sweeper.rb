# -*- encoding : utf-8 -*-
# Sweeper for Event caches
class EventSweeper < ActionController::Caching::Sweeper
  observe Event, Occasion

  def after_save(record)
    invalidate_cache(record)
  end

  def after_destroy(record)
    invalidate_cache(record)
  end

  private

  # Invalidates the cache for a single Event
  def invalidate_cache(record)
    event = record.is_a?(Event) ? record : record.event

    # Could be done using a regex, but this is much more efficient (Rails loops over all cached fragments
    # when using regex)
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/not_bookable/administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/not_online/bookable/administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/not_bookable/administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/not_administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/not_administratable/reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/administratable/not_reportable"
    ActionController::Base.new.expire_fragment "events/show/#{event.id}/occasion_list/online/bookable/administratable/reportable"
  end
end
