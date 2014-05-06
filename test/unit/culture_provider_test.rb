require_relative '../test_helper'

class CultureProviderTest < ActiveSupport::TestCase
  test "validations" do
    culture_provider = build(:culture_provider, name: "")
    assert !culture_provider.valid?
    assert culture_provider.errors.include?(:name)
  end
  test "standing events" do
    culture_provider = create(:culture_provider)
    create_list(:event, 5, culture_provider: culture_provider)
    create_list(:event_with_occasions, 5, culture_provider: culture_provider)

    assert_equal 10, culture_provider.events.length
    assert_equal 5, culture_provider.standing_events.length
    culture_provider.standing_events.each { |e| assert e.occasions.blank? }
  end
  test "upcoming occasions" do
    culture_provider = create(:culture_provider)

    # Not visible
    create(:event_with_occasions,
      culture_provider: culture_provider,
      visible_from: Date.today - 3,
      visible_to: Date.today - 2,
      occasion_dates: [ Date.today + 1 ] # Upcoming
    )

    # Visible
    event = create(:event_with_occasions, culture_provider: culture_provider, occasion_dates: [ Date.today - 1 ]) # No upcoming
    create_list(:occasion, 5, date: Date.today + 1, event: event)

    assert_equal 5, culture_provider.upcoming_occasions.length
    culture_provider.upcoming_occasions.each { |o| assert o.date >= Date.today }
  end

  test "main image" do
    culture_provider = create(:culture_provider)
    images = create_list(:image, 10, culture_provider: culture_provider)
    culture_provider.main_image_id = images.first.id

    assert_equal images.first.id, culture_provider.main_image.id
  end
  test "images excluding main" do
    culture_provider = create(:culture_provider)
    images = create_list(:image, 10, culture_provider: culture_provider)
    culture_provider.main_image_id = images.first.id

    images_excluding_main = culture_provider.images_excluding_main
    assert_equal 9, images_excluding_main.length
    images_excluding_main.each { |i| assert_not_equal images.first.id, i.id }
  end

  test "linked culture providers" do
    culture_provider1 = create(:culture_provider)
    culture_provider2 = create(:culture_provider)
    culture_provider3 = create(:culture_provider, linked_culture_providers: [culture_provider1])

    culture_providers = CultureProvider.not_linked_to_culture_provider(culture_provider3).to_a
    assert_equal 1, culture_providers.length
    assert_equal culture_provider2.id, culture_providers.first.id
  end

  test "linked events" do
    event = create(:event)
    culture_provider1 = create(:culture_provider)
    create(:culture_provider, linked_events: [event])

    culture_providers = CultureProvider.not_linked_to_event(event).to_a
    assert_equal 1, culture_providers.length
    assert_equal culture_provider1.id, culture_providers.first.id
  end
end
