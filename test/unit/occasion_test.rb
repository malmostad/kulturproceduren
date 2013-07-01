require 'test_helper'

class OccasionTest < ActiveSupport::TestCase
  test "validations" do
    occasion = build(:occasion, :date => "")
    assert !occasion.valid?
    assert occasion.errors.include?(:date)
    occasion = build(:occasion, :address => "")
    assert !occasion.valid?
    assert occasion.errors.include?(:address)
    occasion = build(:occasion, :seats => "a")
    assert !occasion.valid?
    assert occasion.errors.include?(:seats)
  end
  
  test "bookings hierarchically ordered" do
    districts = [ create(:district, :name => "adistrict"), create(:district, :name => "bdistrict") ]
    schools = [
      create(:school, :name => "aschool", :district => districts[0]),
      create(:school, :name => "bschool", :district => districts[0]),
      create(:school, :name => "aschool", :district => districts[1]),
      create(:school, :name => "bschool", :district => districts[1]),
    ]
    groups = [
      create(:group, :name => "bgroup", :school => schools[3]),
      create(:group, :name => "agroup", :school => schools[3]),
      create(:group, :name => "bgroup", :school => schools[2]),
      create(:group, :name => "agroup", :school => schools[2]),
      create(:group, :name => "bgroup", :school => schools[1]),
      create(:group, :name => "agroup", :school => schools[1]),
      create(:group, :name => "bgroup", :school => schools[0]),
      create(:group, :name => "agroup", :school => schools[0])
    ]
    occasion = create(:occasion, :seats => 3000, :wheelchair_seats => 3000)
    groups.each { |g| create(:booking, :occasion => occasion, :group => g) }

    ordered_bookings = occasion.bookings.hierarchically_ordered

    0.upto(7) do |i|
      assert groups[7-i].id, ordered_bookings[i].group.id
    end
  end

  test "bookings school ordered" do
    schools = [
      create(:school, :name => "aschool"),
      create(:school, :name => "bschool"),
      create(:school, :name => "cschool"),
      create(:school, :name => "dschool"),
    ]
    groups = [
      create(:group, :name => "bgroup", :school => schools[3]),
      create(:group, :name => "agroup", :school => schools[3]),
      create(:group, :name => "bgroup", :school => schools[2]),
      create(:group, :name => "agroup", :school => schools[2]),
      create(:group, :name => "bgroup", :school => schools[1]),
      create(:group, :name => "agroup", :school => schools[1]),
      create(:group, :name => "bgroup", :school => schools[0]),
      create(:group, :name => "agroup", :school => schools[0])
    ]
    occasion = create(:occasion, :seats => 3000, :wheelchair_seats => 3000)
    groups.each { |g| create(:booking, :occasion => occasion, :group => g) }

    ordered_bookings = occasion.bookings.school_ordered

    0.upto(7) do |i|
      assert groups[7-i].id, ordered_bookings[i].group.id
    end
  end

  test "groups hierarchically ordered" do
    districts = [ create(:district, :name => "adistrict"), create(:district, :name => "bdistrict") ]
    schools = [
      create(:school, :name => "aschool", :district => districts[0]),
      create(:school, :name => "bschool", :district => districts[0]),
      create(:school, :name => "aschool", :district => districts[1]),
      create(:school, :name => "bschool", :district => districts[1]),
    ]
    groups = [
      create(:group, :name => "bgroup", :school => schools[3]),
      create(:group, :name => "agroup", :school => schools[3]),
      create(:group, :name => "bgroup", :school => schools[2]),
      create(:group, :name => "agroup", :school => schools[2]),
      create(:group, :name => "bgroup", :school => schools[1]),
      create(:group, :name => "agroup", :school => schools[1]),
      create(:group, :name => "bgroup", :school => schools[0]),
      create(:group, :name => "agroup", :school => schools[0])
    ]
    occasion = create(:occasion)
    groups.each { |g| create(:ticket, :occasion => occasion, :group => g) }

    ordered_groups = occasion.groups.hierarchically_ordered

    0.upto(7) do |i|
      assert groups[7-i].id, ordered_groups[i].id
    end
  end

  test "groups school ordered" do
    schools = [
      create(:school, :name => "aschool"),
      create(:school, :name => "bschool"),
      create(:school, :name => "cschool"),
      create(:school, :name => "dschool"),
    ]
    groups = [
      create(:group, :name => "bgroup", :school => schools[3]),
      create(:group, :name => "agroup", :school => schools[3]),
      create(:group, :name => "bgroup", :school => schools[2]),
      create(:group, :name => "agroup", :school => schools[2]),
      create(:group, :name => "bgroup", :school => schools[1]),
      create(:group, :name => "agroup", :school => schools[1]),
      create(:group, :name => "bgroup", :school => schools[0]),
      create(:group, :name => "agroup", :school => schools[0])
    ]
    occasion = create(:occasion)
    groups.each { |g| create(:ticket, :occasion => occasion, :group => g) }

    ordered_groups = occasion.groups.school_ordered

    0.upto(7) do |i|
      assert groups[7-i].id, ordered_groups[i].id
    end
  end
  
  test "attending groups" do
    occasion           = create(:occasion)
    attending          = create_list(:group, 3)
    not_attending      = create_list(:group, 3)
    attending.each     { |g| create(:ticket, :occasion => occasion, :group => g, :state => :booked) }
    not_attending.each { |g| create(:ticket, :occasion => occasion, :group => g, :state => :unbooked) }

    attending_ids = attending.collect(&:id)
    not_attending_ids = not_attending.collect(&:id)

    occasion.attending_groups.each do |group|
      assert attending_ids.include?(group.id)
      assert !not_attending_ids.include?(group.id)
    end
  end

  test "upcoming" do
    ts = Time.zone.now
    # Yesterday
    create(:occasion,
      :date       => Date.yesterday,
      :start_time => (ts - 23.hours).strftime("%H:%M"),
      :stop_time  => (ts - 22.hours).strftime("%H:%M"))
    # Today, but the entire occasion has passed
    create(:occasion,
      :date       => Date.today,
      :start_time => (ts - 2.hour).strftime("%H:%M"),
      :stop_time  => (ts - 1.hours).strftime("%H:%M"))
    # Today, occasion has started but not ended
    create(:occasion,
      :date       => Date.today,
      :start_time => (ts - 1.hour).strftime("%H:%M"),
      :stop_time  => (ts + 1.hours).strftime("%H:%M"))
    # Today, occasion has not started
    create(:occasion,
      :date       => Date.today,
      :start_time => (ts + 1.hour).strftime("%H:%M"),
      :stop_time  => (ts + 2.hours).strftime("%H:%M"))
    # Tomorrow
    create(:occasion,
      :date       => Date.tomorrow,
      :start_time => (ts + 22.hours).strftime("%H:%M"),
      :stop_time  => (ts + 23.hours).strftime("%H:%M"))

    result = Occasion.upcoming.all
    assert_equal 2, result.length # The last two defined above

    result.each do |occasion|
      assert occasion.date              >= Date.today

      if occasion.date == Date.today
        assert occasion.start_time.hour >= ts.hour
        assert occasion.start_time.min  >= ts.min
      end
    end
  end

  test "ticket usage" do
    occasion = create(:occasion)
    create_list(:ticket, 5, :occasion => occasion, :state => :booked)
    create_list(:ticket, 2, :occasion => occasion, :state => :unbooked)
    total, booked = occasion.ticket_usage

    assert_equal 7, total
    assert_equal 5, booked
  end

  def search(filter)
    Occasion.search(filter, 1).map(&:id)
  end

  def occasion_for_event(event_params, occasion_params = {})
    event = create(:event, event_params)
    create(:occasion, occasion_params.merge(:event => event))
  end

  test "search" do
    old_per_page = Occasion.per_page
    Occasion.per_page = 100 # Disable paging

    # Default
    create(:occasion)

    # Default exclusions
    event_not_visible = occasion_for_event(:visible_to => Date.today - 1).id
    cancelled = create(:occasion, :cancelled => true).id
    inactive_culture_provider = occasion_for_event(:culture_provider => create(:culture_provider, :active => false)).id

    result = search({})
    assert_equal 1, result.length
    assert !result.include?(event_not_visible)
    assert !result.include?(cancelled)
    assert !result.include?(inactive_culture_provider)

    # Free text
    freetext1 = occasion_for_event(:name => "freetext1").id
    freetext2 = occasion_for_event(:description => "freetext2").id

    result = search(:free_text => "freetext")
    assert_equal 2, result.length
    assert result.include?(freetext1)
    assert result.include?(freetext2)

    # Further education
    further_education = occasion_for_event(:further_education => true, :from_age => 10, :to_age => 11).id
    result = search(:further_education => true, :from_age => 12, :to_age => 13)
    assert_equal 1, result.length
    assert_equal further_education, result.first

    # Age
    with_age = occasion_for_event(:from_age => 10, :to_age => 11).id
    result = search(:from_age => -1, :to_age => -1)
    assert result.include?(with_age)
    result = search(:from_age => 12)
    assert !result.include?(with_age)
    result = search(:to_age => 9)
    assert !result.include?(with_age)

    # Date
    old_occasion = create(:occasion, :date => Date.today - 1).id
    result = search({})
    assert !result.include?(old_occasion)
    result = search(:from_date => Date.today - 1)
    assert result.include?(old_occasion)

    # Date span
    future_occasions = [
      create(:occasion, :date => Date.today).id,
      create(:occasion, :date => Date.today + 6).id,
      create(:occasion, :date => Date.today + 27).id,
      create(:occasion, :date => Date.today + 200).id,
      create(:occasion, :date => Date.today + 400).id
    ]

    result = search({})
    future_occasions.each { |e| assert result.include?(e) }
    result = search(:date_span => :day)
    assert result.include?(future_occasions.first)
    future_occasions.last(4).each { |e| assert !result.include?(e) }
    result = search(:date_span => :week)
    future_occasions.first(2).each { |e| assert result.include?(e) }
    future_occasions.last(3).each { |e| assert !result.include?(e) }
    result = search(:date_span => :month)
    future_occasions.first(3).each { |e| assert result.include?(e) }
    future_occasions.last(2).each { |e| assert !result.include?(e) }
    result = search(:date_span => :date, :to_date => Date.today + 300)
    future_occasions.first(4).each { |e| assert result.include?(e) }
    assert !result.include?(future_occasions.last)

    # Categories
    categories = create_list(:category, 2)
    events = create_list(:event, 2)
    events.first.categories << categories.first
    events.second.categories << categories.second

    first = create(:occasion, :event => events.first).id
    second = create(:occasion, :event => events.second).id

    result = search({})
    [first, second].each { |e| assert result.include?(e) }
    result = search(:categories => categories.first.id)
    assert result.include?(first)
    assert !result.include?(second)
    result = search(:categories => categories.collect(&:id))
    [first, second].each { |e| assert result.include?(e) }

    Occasion.per_page = old_per_page
  end

  test "available wheelchair seats" do
    occasion = create(:occasion, :wheelchair_seats => 10)
    create(:ticket, :occasion => occasion, :wheelchair => true, :state => :booked)
    create(:ticket, :occasion => occasion, :wheelchair => true, :state => :used)
    create(:ticket, :occasion => occasion, :wheelchair => true, :state => :not_used)
    create(:ticket, :occasion => occasion, :wheelchair => true, :state => :unbooked)
    create(:ticket, :occasion => occasion, :wheelchair => true, :state => :deactivated)

    assert_equal 7, occasion.available_wheelchair_seats
  end

  test "available seats" do
    occasion = create(:occasion, :seats => 5, :wheelchair_seats => 5)
    create(:ticket, :occasion => occasion, :state => :booked)
    create(:ticket, :occasion => occasion, :state => :used)
    create(:ticket, :occasion => occasion, :state => :not_used)
    create(:ticket, :occasion => occasion, :state => :unbooked)
    create(:ticket, :occasion => occasion, :state => :deactivated)

    assert_equal 6, occasion.available_seats

    occasion = create(:occasion, :seats => 4, :wheelchair_seats => 4, :single_group => true)
    create(:ticket, :occasion => occasion, :state => :booked)
    create(:ticket, :occasion => occasion, :state => :used)
    create(:ticket, :occasion => occasion, :state => :not_used)
    create(:ticket, :occasion => occasion, :state => :unbooked)
    create(:ticket, :occasion => occasion, :state => :deactivated)

    assert_equal 0, occasion.available_seats
    assert_equal 5, occasion.available_seats(true)
  end

  test "bus booking?" do
    event = create(:event, :bus_booking => true, :ticket_state => :alloted_group)
    occasion = create(
      :occasion,
      :event => event
    )

    assert occasion.bus_booking?

    # Event must have bus booking activated
    event.bus_booking = false
    assert !occasion.bus_booking?
    event.bus_booking = true
    assert occasion.bus_booking?

    # Event must be alloted to group
    event.ticket_state = :alloted_district
    assert !occasion.bus_booking?
    event.ticket_state = :alloted_group
    assert occasion.bus_booking?
  end
end
