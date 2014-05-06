require_relative '../test_helper'

class EventTest < ActiveSupport::TestCase
  test "validations" do
    event = build(:event, name: "")
    assert !event.valid?
    assert event.errors.include?(:name)
    event = build(:event, description: "")
    assert !event.valid?
    assert event.errors.include?(:description)
    event = build(:event, from_age: "a")
    assert !event.valid?
    assert event.errors.include?(:from_age)
    event = build(:event, to_age: "a")
    assert !event.valid?
    assert event.errors.include?(:to_age)
    event = build(:event, visible_from: "")
    assert !event.valid?
    assert event.errors.include?(:visible_from)
    event = build(:event, visible_to: "")
    assert !event.valid?
    assert event.errors.include?(:visible_to)
  end

  test "standing" do
    create_list(:event, 5)
    create_list(:event_with_occasions, 5)

    events = Event.standing.to_a
    assert_equal 5, events.length
    events.each { |e| assert e.occasions.blank? }
  end
  test "non standing" do
    create_list(:event, 5)
    create_list(:event_with_occasions, 5)

    events = Event.non_standing.to_a
    assert_equal 5, events.length
    events.each { |e| assert !e.occasions.blank? }
  end

  test "without tickets" do
    with = create(:event)
    without = create(:event)
    create(:ticket, event: with)

    events = Event.without_tickets.to_a
    assert_equal 1, events.length
    assert_equal without.id, events.first.id
  end
  test "without questionnaires" do
    with = create(:event)
    without = create(:event)
    create(:questionnaire, event: with)

    events = Event.without_questionnaires.to_a
    assert_equal 1, events.length
    assert_equal without.id, events.first.id
  end

  test "linked events" do
    event1 = create(:event)
    event2 = create(:event)
    event3 = create(:event, linked_events: [event1])

    events = Event.not_linked_to_event(event3).to_a
    assert_equal 1, events.length
    assert_equal event2.id, events.first.id
  end
  test "linked culture providers" do
    culture_provider = create(:culture_provider)
    event1 = create(:event)
    create(:event, linked_culture_providers: [culture_provider])

    events = Event.not_linked_to_culture_provider(culture_provider).to_a
    assert_equal 1, events.length
    assert_equal event1.id, events.first.id
  end

  test "booked users" do
    event = create(:event)
    users = create_list(:user, 2)
    create_list(:ticket, 3, event: event, user: users.first,  state: :booked)
    create_list(:ticket, 3, event: event, user: users.first,  state: :unbooked)
    create_list(:ticket, 3, event: event, user: users.second, state: :unbooked)

    booked_users = event.booked_users
    assert_equal 1, booked_users.length
    assert_equal users.first.id, booked_users.first.id
  end

  test "groups by district" do
    event = create(:event)
    districts = create_list(:district, 2)

    districts.each do |d|
      create_list(:school, 2, district: d).each do |s|
        create_list(:group, 2, school: s).each do |g|
          create_list(:ticket, 2, district: d, group: g, event: event)
        end
      end
    end

    event.groups.find_by_district(districts.first).each do |g|
      assert_equal districts.first.id, g.school.district.id
    end
  end

  test "reportable occasions" do
    event = create(:event)
    create_list(:occasion, 5, event: event, date: Date.today)
    create_list(:occasion, 6, event: event, date: Date.today - 1)
    assert_equal 6, event.reportable_occasions.length
    event.reportable_occasions.each { |o| assert o.date < Date.today }
  end

  test "main image" do
    event = create(:event)
    images = create_list(:image, 10, event: event)
    event.main_image_id = images.first.id

    assert_equal images.first.id, event.main_image.id
  end
  test "images excluding main" do
    event = create(:event)
    images = create_list(:image, 10, event: event)
    event.main_image_id = images.first.id

    images_excluding_main = event.images_excluding_main
    assert_equal 9, images_excluding_main.length
    images_excluding_main.each { |i| assert_not_equal images.first.id, i.id }
  end

  test "further education age" do
    event = create(:event, further_education: true, from_age: 10, to_age: 11)
    assert_equal -1, event.from_age
    assert_equal -1, event.to_age
  end

  test "ticket state" do
    event = Event.new

    event.ticket_state = :alloted_group
    assert_equal :alloted_group, event.ticket_state
    event.ticket_state = :alloted_district
    assert_equal :alloted_district, event.ticket_state
    event.ticket_state = :free_for_all
    assert_equal :free_for_all, event.ticket_state

    event.ticket_state = Event::ALLOTED_GROUP
    assert_equal :alloted_group, event.ticket_state
    event.ticket_state = Event::ALLOTED_DISTRICT
    assert_equal :alloted_district, event.ticket_state
    event.ticket_state = Event::FREE_FOR_ALL
    assert_equal :free_for_all, event.ticket_state

    event.ticket_state = :zomg
    assert_nil event.ticket_state
    event.ticket_state = -3
    assert_nil event.ticket_state
  end
  test "alloted group?" do
    assert !Event.new(ticket_state: nil).alloted_group?
    assert  Event.new(ticket_state: :alloted_group).alloted_group?
    assert  Event.new(ticket_state: Event::ALLOTED_GROUP).alloted_group?
    assert !Event.new(ticket_state: :alloted_district).alloted_group?
    assert !Event.new(ticket_state: Event::ALLOTED_DISTRICT).alloted_group?
    assert !Event.new(ticket_state: :free_for_all).alloted_group?
    assert !Event.new(ticket_state: Event::FREE_FOR_ALL).alloted_group?
  end
  test "alloted district?" do
    assert !Event.new(ticket_state: nil).alloted_district?
    assert !Event.new(ticket_state: :alloted_group).alloted_district?
    assert !Event.new(ticket_state: Event::ALLOTED_GROUP).alloted_district?
    assert  Event.new(ticket_state: :alloted_district).alloted_district?
    assert  Event.new(ticket_state: Event::ALLOTED_DISTRICT).alloted_district?
    assert !Event.new(ticket_state: :free_for_all).alloted_district?
    assert !Event.new(ticket_state: Event::FREE_FOR_ALL).alloted_district?
  end
  test "free for all?" do
    assert !Event.new(ticket_state: nil).free_for_all?
    assert !Event.new(ticket_state: :alloted_group).free_for_all?
    assert !Event.new(ticket_state: Event::ALLOTED_GROUP).free_for_all?
    assert !Event.new(ticket_state: :alloted_district).free_for_all?
    assert !Event.new(ticket_state: Event::ALLOTED_DISTRICT).free_for_all?
    assert  Event.new(ticket_state: :free_for_all).free_for_all?
    assert  Event.new(ticket_state: Event::FREE_FOR_ALL).free_for_all?
  end

  test "transition to district?" do
    assert  create(:event, ticket_state: :alloted_group,    district_transition_date: Date.today    ).transition_to_district?
    assert  create(:event, ticket_state: :alloted_group,    district_transition_date: Date.today - 1).transition_to_district?
    assert !create(:event, ticket_state: :alloted_group,    district_transition_date: Date.today + 1).transition_to_district?
    assert !create(:event, ticket_state: :alloted_district, district_transition_date: Date.today    ).transition_to_district?
    assert !create(:event, ticket_state: :alloted_group,    district_transition_date: nil           ).transition_to_district?
  end
  test "transition to district!" do
    event = create(:event, ticket_state: :alloted_group, district_transition_date: Date.today)
    event.transition_to_district!
    assert Event.find(event.id).alloted_district?
  end
  test "transition to free for all?" do
    assert  create(:event, ticket_state: :alloted_district, free_for_all_transition_date: Date.today    ).transition_to_free_for_all?
    assert  create(:event, ticket_state: :alloted_district, free_for_all_transition_date: Date.today - 1).transition_to_free_for_all?
    assert !create(:event, ticket_state: :alloted_district, free_for_all_transition_date: Date.today + 1).transition_to_free_for_all?
    assert !create(:event, ticket_state: :free_for_all,     free_for_all_transition_date: Date.today    ).transition_to_free_for_all?

    assert  create(:event, ticket_state: :alloted_group,    free_for_all_transition_date: Date.today,   district_transition_date: nil).transition_to_free_for_all?
  end
  test "transition to free for all!" do
    event = create(:event, ticket_state: :alloted_district, free_for_all_transition_date: Date.today)
    event.transition_to_free_for_all!
    assert Event.find(event.id).free_for_all?
  end

  test "bookable" do
    event = create(:event_with_occasions,
      visible_from: Date.today - 1,
      visible_to: Date.today + 1,
      ticket_release_date: Date.today - 1
    )
    create_list(:ticket, 5, event: event)

    assert event.bookable?(true)

    event.visible_from = Date.today + 1
    assert !event.bookable?(true)
    event.visible_from = Date.today - 1
    assert event.bookable?(true)

    event.visible_to = Date.today - 1
    assert !event.bookable?(true)
    event.visible_to = Date.today + 1
    assert event.bookable?(true)

    event.ticket_release_date = nil
    assert !event.bookable?(true)
    event.ticket_release_date = Date.today + 1
    assert !event.bookable?(true)
    event.ticket_release_date = Date.today - 1
    assert event.bookable?(true)

    event.tickets.clear
    assert !event.bookable?(true)
    create_list(:ticket, 5, event: event)
    event.tickets(true)
    assert event.bookable?(true)

    event.occasions.clear
    assert !event.bookable?(true)
    create_list(:occasion, 5, event: event)
    event.occasions(true)
    assert event.bookable?(true)
  end
  test "reportable" do
    event = create(:event_with_occasions,
      visible_from: Date.today - 1,
      ticket_release_date: Date.today - 1
    )
    create_list(:ticket, 5, event: event)

    assert event.reportable?(true)

    event.visible_from = Date.today + 1
    assert !event.reportable?(true)
    event.visible_from = Date.today - 1
    assert event.reportable?(true)

    event.ticket_release_date = nil
    assert !event.reportable?(true)
    event.ticket_release_date = Date.today + 1
    assert !event.reportable?(true)
    event.ticket_release_date = Date.today - 1
    assert event.reportable?(true)

    event.tickets.clear
    assert !event.reportable?(true)
    create_list(:ticket, 5, event: event)
    event.tickets(true)
    assert event.reportable?(true)

    event.occasions.clear
    assert !event.reportable?(true)
    create_list(:occasion, 5, event: event)
    event.occasions(true)
    assert event.reportable?(true)
  end

  test "ticket count by group" do
    event = create(:event)
    groups = create_list(:group, 2)
    create_list(:ticket, 5, event: event, group: groups.first)
    create_list(:ticket, 6, event: event, group: groups.second)
    create_list(:ticket, 1, group: groups.second) # dummy

    count = event.ticket_count_by_group
    assert_equal 5, count[groups.first.id]
    assert_equal 6, count[groups.second.id]
  end
  test "ticket count by district" do
    event = create(:event)
    districts = create_list(:district, 2)
    create_list(:ticket, 5, event: event, district: districts.first)
    create_list(:ticket, 6, event: event, district: districts.second)
    create_list(:ticket, 1, district: districts.second) # dummy

    count = event.ticket_count_by_district
    assert_equal 5, count[districts.first.id]
    assert_equal 6, count[districts.second.id]
  end

  test "has booking" do
    event = create(:event)
    assert !event.has_booking?
    create_list(:ticket, 5, event: event)
    assert !event.has_booking?
    create_list(:ticket, 5, event: event, state: :booked)
    assert event.has_booking?
  end
  test "unbooked tickets" do
    event = create(:event)
    assert !event.has_unbooked_tickets?(true)
    assert_equal 0, event.unbooked_tickets(true)
    create_list(:ticket, 5, event: event, state: :booked)
    assert !event.has_unbooked_tickets?(true)
    assert_equal 0, event.unbooked_tickets(true)
    create_list(:ticket, 5, event: event, state: :unbooked)
    assert event.has_unbooked_tickets?(true)
    assert_equal 5, event.unbooked_tickets(true)
  end

  test "fully booked" do
    event = create(:event)

    # Unbooked tickets
    tickets = create_list(:ticket, 2, event: event, state: :unbooked)

    ts = Time.zone.now

    # Old occasions, should not count
    create(:occasion,
      event: event,
      date: Date.yesterday,
      start_time: (ts - 24.hours).strftime("%H:%M"),
      stop_time: (ts - 23.hours).strftime("%H:%M"))
    create(:occasion,
      event: event,
      date: Date.today,
      start_time: (ts - 1.hours).strftime("%H:%M"),
      stop_time: (ts + 1.hours).strftime("%H:%M"))

    # Available seats
    occasions = create_list(:occasion, 2, event: event, single_group: true) # No booked tickets

    assert !event.fully_booked?(true)

    # Book the tickets
    tickets.each { |t| t.state = :booked; t.save }
    assert event.fully_booked?(true)

    create_list(:ticket, 2, event: event, state: :unbooked)
    assert !event.fully_booked?(true)

    # Assign booked tickets to single group occasions
    tickets.each { |t| t.occasion = occasions.pop; t.save }
    event.occasions(true)
    assert event.fully_booked?(true)
    
    create_list(:occasion, 2, event: event, single_group: true)
    event.occasions(true)
    assert !event.fully_booked?(true)
  end

  test "has available seats" do
    event = create(:event)

    ts = Time.zone.now

    # Old occasions, should not count
    create(:occasion,
      event: event,
      date: Date.yesterday,
      start_time: (ts - 24.hours).strftime("%H:%M"),
      stop_time: (ts - 23.hours).strftime("%H:%M"))
    create(:occasion,
      event: event,
      date: Date.today,
      start_time: (ts - 1.hours).strftime("%H:%M"),
      stop_time: (ts + 1.hours).strftime("%H:%M"))

    # This uses Occasion#available_seats
    # No available seats for an occasion if it has at least one booked ticket and is a single group occasion
    create_list(:occasion_with_booked_tickets, 2, event: event, single_group: true)
    assert !event.has_available_seats?

    create_list(:occasion, 2, event: event, single_group: true) # No booked tickets
    event.occasions(true)
    assert event.has_available_seats?
  end

  test "ticket usage" do
    event = create(:event)
    create_list(:ticket, 5, event: event, state: :unbooked)
    create_list(:ticket, 6, event: event, state: :booked)
    create_list(:ticket, 1, event: event, state: :used)
    create_list(:ticket, 2, event: event, state: :not_used)
    create_list(:ticket, 3, event: event, state: :deactivated)

    usage = event.ticket_usage
    assert_equal 2, usage.length
    total, booked = usage
    assert_equal 1+2+3+5+6, total
    assert_equal 6, booked
  end

  test "not targeted group ids" do
    event = create(:event, from_age: 10, to_age: 11)
    targeted1    = create(:group_with_age_groups, age_group_data: [[10,20]])
    targeted2    = create(:group_with_age_groups, age_group_data: [[11,20]])
    not_targeted = create(:group_with_age_groups, age_group_data: [[9,20]])

    create_list(:ticket, 2, event: event, group: targeted1)
    create_list(:ticket, 2, event: event, group: targeted2)
    create_list(:ticket, 2, event: event, group: not_targeted)

    ids = event.not_targeted_group_ids
    assert_equal 1, ids.length
    assert_equal not_targeted.id, ids.first
  end

  test "has bus bookings?" do
    booking = create(:booking, bus_booking: true, bus_stop: "bus stop")
    assert booking.event.has_bus_bookings?
    booking = create(:booking, bus_booking: false)
    assert !booking.event.has_bus_bookings?
  end

  def search_standing(filter)
    Event.search_standing(filter, 1).map(&:id)
  end

  test "search standing" do
    old_per_page = Event.per_page
    Event.per_page = 100 # Disable paging

    # Default
    create(:event, further_education: false, from_age: 7, to_age: 9)

    # Default exclusions
    with_occasions = create(:event_with_occasions).id
    inactive = create(:event, culture_provider: create(:culture_provider, active: false)).id

    result = search_standing({})
    assert_equal 1, result.length
    assert !result.include?(with_occasions)
    assert !result.include?(inactive)

    # Free text
    freetext1 = create(:event, name: "freetext1").id
    freetext2 = create(:event, description: "freetext2").id

    result = search_standing(free_text: "freetext")
    assert_equal 2, result.length
    assert result.include?(freetext1)
    assert result.include?(freetext2)

    # Further education
    further_education = create(:event, further_education: true, from_age: 10, to_age: 11).id
    result = search_standing(further_education: true, from_age: 12, to_age: 13)
    assert_equal 1, result.length
    assert_equal further_education, result.first

    # Age
    with_age = create(:event, from_age: 10, to_age: 11).id
    result = search_standing(from_age: -1, to_age: -1)
    assert result.include?(with_age)
    result = search_standing(from_age: 12)
    assert !result.include?(with_age)
    result = search_standing(to_age: 9)
    assert !result.include?(with_age)

    # Date
    old_event = create(:event, visible_to: Date.today - 1).id
    result = search_standing({})
    assert !result.include?(old_event)
    result = search_standing(from_date: Date.today - 1)
    assert result.include?(old_event)

    # Date span
    future_events = [
      create(:event, visible_from: Date.today + 1,   visible_to: Date.today + 1).id,
      create(:event, visible_from: Date.today + 1.week,   visible_to: Date.today + 1.week).id,
      create(:event, visible_from: Date.today + 1.month,  visible_to: Date.today + 1.month).id,
      create(:event, visible_from: Date.today + 1.year, visible_to: Date.today + 1.year).id
    ]

    result = search_standing({})
    future_events.each { |e| assert result.include?(e) }
    result = search_standing(date_span: :day)
    assert result.include?(future_events.first)
    future_events.last(3).each { |e| assert !result.include?(e) }
    result = search_standing(date_span: :week)
    future_events.first(2).each { |e| assert result.include?(e) }
    future_events.last(2).each { |e| assert !result.include?(e) }
    result = search_standing(date_span: :month)
    future_events.first(3).each { |e| assert result.include?(e) }
    assert !result.include?(future_events.last)

    # From date + date span
    result = search_standing(from_date: Date.today - 1, date_span: :day)
    future_events.each { |e| assert !result.include?(e) }
    result = search_standing(from_date: Date.today - 1, date_span: :week)
    assert result.include?(future_events.first)
    future_events.last(3).each { |e| assert !result.include?(e) }
    result = search_standing(from_date: Date.today - 1, date_span: :month)
    future_events.first(2).each { |e| assert result.include?(e) }
    future_events.last(2).each { |e| assert !result.include?(e) }

    # Categories
    categories = create_list(:category, 2)
    events = create_list(:event, 2)
    events.first.categories << categories.first
    events.second.categories << categories.second

    result = search_standing({})
    events.each { |e| assert result.include?(e.id) }
    result = search_standing(categories: categories.first.id)
    assert result.include?(events.first.id)
    assert !result.include?(events.second.id)
    result = search_standing(categories: categories.collect(&:id))
    events.each { |e| assert result.include?(e.id) }

    Event.per_page = old_per_page
  end

  test "get visitor stats for events" do
    # TODO
  end
end
