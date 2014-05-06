require_relative '../test_helper'

class TicketTest < ActiveSupport::TestCase
  test "state" do
    ticket = Ticket.new

    ticket.state = :unbooked
    assert_equal :unbooked, ticket.state
    ticket.state = :booked
    assert_equal :booked, ticket.state
    ticket.state = :used
    assert_equal :used, ticket.state
    ticket.state = :not_used
    assert_equal :not_used, ticket.state
    ticket.state = :deactivated
    assert_equal :deactivated, ticket.state

    ticket.state = Ticket::UNBOOKED
    assert_equal :unbooked, ticket.state
    ticket.state = Ticket::BOOKED
    assert_equal :booked, ticket.state
    ticket.state = Ticket::USED
    assert_equal :used, ticket.state
    ticket.state = Ticket::NOT_USED
    assert_equal :not_used, ticket.state
    ticket.state = Ticket::DEACTIVATED
    assert_equal :deactivated, ticket.state

    ticket.state = :zomg
    assert_equal :unbooked, ticket.state
    ticket.state = 100
    assert_equal :unbooked, ticket.state
  end
  test "unbooked?" do
    assert Ticket.new(state: :unbooked).unbooked?
    assert Ticket.new(state: Ticket::UNBOOKED).unbooked?
    assert !Ticket.new(state: :booked).unbooked?
    assert !Ticket.new(state: Ticket::BOOKED).unbooked?
    assert !Ticket.new(state: :used).unbooked?
    assert !Ticket.new(state: Ticket::USED).unbooked?
    assert !Ticket.new(state: :not_used).unbooked?
    assert !Ticket.new(state: Ticket::NOT_USED).unbooked?
    assert !Ticket.new(state: :deactivated).unbooked?
    assert !Ticket.new(state: Ticket::DEACTIVATED).unbooked?
  end
  test "booked?" do
    assert !Ticket.new(state: :unbooked).booked?
    assert !Ticket.new(state: Ticket::UNBOOKED).booked?
    assert Ticket.new(state: :booked).booked?
    assert Ticket.new(state: Ticket::BOOKED).booked?
    assert !Ticket.new(state: :used).booked?
    assert !Ticket.new(state: Ticket::USED).booked?
    assert !Ticket.new(state: :not_used).booked?
    assert !Ticket.new(state: Ticket::NOT_USED).booked?
    assert !Ticket.new(state: :deactivated).booked?
    assert !Ticket.new(state: Ticket::DEACTIVATED).booked?
  end
  test "used?" do
    assert !Ticket.new(state: :unbooked).used?
    assert !Ticket.new(state: Ticket::UNBOOKED).used?
    assert !Ticket.new(state: :booked).used?
    assert !Ticket.new(state: Ticket::BOOKED).used?
    assert Ticket.new(state: :used).used?
    assert Ticket.new(state: Ticket::USED).used?
    assert !Ticket.new(state: :not_used).used?
    assert !Ticket.new(state: Ticket::NOT_USED).used?
    assert !Ticket.new(state: :deactivated).used?
    assert !Ticket.new(state: Ticket::DEACTIVATED).used?
  end
  test "not used?" do
    assert !Ticket.new(state: :unbooked).not_used?
    assert !Ticket.new(state: Ticket::UNBOOKED).not_used?
    assert !Ticket.new(state: :booked).not_used?
    assert !Ticket.new(state: Ticket::BOOKED).not_used?
    assert !Ticket.new(state: :used).not_used?
    assert !Ticket.new(state: Ticket::USED).not_used?
    assert Ticket.new(state: :not_used).not_used?
    assert Ticket.new(state: Ticket::NOT_USED).not_used?
    assert !Ticket.new(state: :deactivated).not_used?
    assert !Ticket.new(state: Ticket::DEACTIVATED).not_used?
  end
  test "deactivated?" do
    assert !Ticket.new(state: :unbooked).deactivated?
    assert !Ticket.new(state: Ticket::UNBOOKED).deactivated?
    assert !Ticket.new(state: :booked).deactivated?
    assert !Ticket.new(state: Ticket::BOOKED).deactivated?
    assert !Ticket.new(state: :used).deactivated?
    assert !Ticket.new(state: Ticket::USED).deactivated?
    assert !Ticket.new(state: :not_used).deactivated?
    assert !Ticket.new(state: Ticket::NOT_USED).deactivated?
    assert Ticket.new(state: :deactivated).deactivated?
    assert Ticket.new(state: Ticket::DEACTIVATED).deactivated?
  end

  # Tests with_scope, unbooked, booked, used, not_used and deactivated methods
  test "state scope methods" do
    unbooked    = create(:ticket, state: :unbooked)
    booked      = create(:ticket, state: :booked)
    used        = create(:ticket, state: :used)
    not_used    = create(:ticket, state: :not_used)
    deactivated = create(:ticket, state: :deactivated)

    assert_equal [unbooked],    Ticket.with_states(:unbooked).to_a
    assert_equal [booked],      Ticket.with_states(:booked).to_a
    assert_equal [used],        Ticket.with_states(:used).to_a
    assert_equal [not_used],    Ticket.with_states(:not_used).to_a
    assert_equal [deactivated], Ticket.with_states(:deactivated).to_a

    assert_equal [deactivated, unbooked, used], Ticket.with_states(:unbooked, :used, :deactivated).order(:state).to_a
    assert_equal [booked, not_used],            Ticket.with_states([:booked, :not_used]).order(:state).to_a

    assert_equal [unbooked],    Ticket.unbooked.to_a
    assert_equal [booked],      Ticket.booked.to_a
    assert_equal [used],        Ticket.used.to_a
    assert_equal [not_used],    Ticket.not_used.to_a
    assert_equal [deactivated], Ticket.deactivated.to_a

    assert_equal [deactivated, booked, used, not_used],     Ticket.without_states(:unbooked).order(:state).to_a
    assert_equal [deactivated, unbooked, used, not_used],   Ticket.without_states(:booked).order(:state).to_a
    assert_equal [deactivated, unbooked, booked, not_used], Ticket.without_states(:used).order(:state).to_a
    assert_equal [deactivated, unbooked, booked, used],     Ticket.without_states(:not_used).order(:state).to_a
    assert_equal [unbooked, booked, used, not_used],        Ticket.without_states(:deactivated).order(:state).to_a

    assert_equal [deactivated, unbooked, used], Ticket.without_states([:booked, :not_used]).order(:state).to_a
    assert_equal [booked, not_used],            Ticket.without_states(:unbooked, :used, :deactivated).order(:state).to_a

    assert_equal [deactivated, booked, used, not_used],   Ticket.not_unbooked.order(:state).to_a
    assert_equal [deactivated, unbooked, used, not_used], Ticket.not_booked.order(:state).to_a
    assert_equal [unbooked, booked, used, not_used],      Ticket.not_deactivated.order(:state).to_a
  end

  test "unbook!" do
    booking = create(:booking)

    ticket = create(
      :ticket,
      state: :booked,
      booking: booking,
      user: booking.user,
      occasion: booking.occasion,
      wheelchair: true,
      adult: true,
      booked_when: Time.now
    )

    ticket.unbook!

    assert       ticket.unbooked?
    assert_nil   ticket.booking
    assert_nil   ticket.user
    assert_nil   ticket.occasion
    assert       !ticket.wheelchair
    assert       !ticket.adult
    assert_nil   ticket.booked_when

    ticket = create(
      :ticket,
      state: :unbooked,
      booking: booking,
      user: booking.user,
      occasion: booking.occasion,
      wheelchair: true,
      adult: true,
      booked_when: Time.now
    )

    ticket.unbook!

    assert           ticket.unbooked?
    assert_not_nil   ticket.booking
    assert_not_nil   ticket.user
    assert_not_nil   ticket.occasion
    assert           ticket.wheelchair
    assert           ticket.adult
    assert_not_nil   ticket.booked_when
  end

  test "count wheelchair by occasion" do
    occasion = create(:occasion)
    create_list(:ticket, 10, occasion: occasion, state: :booked,   wheelchair: true)
    create_list(:ticket, 10, occasion: occasion, state: :used,     wheelchair: true)
    create_list(:ticket, 10, occasion: occasion, state: :not_used, wheelchair: true)

    create_list(:ticket, 1,  occasion: occasion, state: :booked,   wheelchair: false)
    create_list(:ticket, 1,  occasion: occasion, state: :unbooked, wheelchair: true)
    create_list(:ticket, 1,                         state: :booked,   wheelchair: true)

    assert_equal 30, Ticket.count_wheelchair_by_occasion(occasion)
  end

  test "find user bookings" do
    user        = create(:user)
    user_n      = create(:user)
    groups      = create_list(:group, 2)
    occasions   = [
      create(:occasion, date: Date.today - 1),
      create(:occasion, date: Date.today - 2)
    ]

    create_list(:ticket, 4, occasion: occasions.first,  user: user, group: groups.first,  state: :booked)
    create_list(:ticket, 4, occasion: occasions.second, user: user, group: groups.first,  state: :booked)
    create_list(:ticket, 4, occasion: occasions.first,  user: user, group: groups.second, state: :booked)
    create_list(:ticket, 4, occasion: occasions.second, user: user, group: groups.second, state: :booked)

    create(:ticket, occasion: occasions.first, user: user,   group: groups.first, state: :unbooked)
    create(:ticket, occasion: occasions.first, user: user_n, group: groups.first, state: :booked)

    bookings = Ticket.find_user_bookings(user, 1)
    assert_equal 4, bookings.length
    bookings.each do |t|
      assert_equal user.id, t.user.id
      assert_equal 4, t.num_tickets.to_i
      assert occasions.collect(&:id).include?(t.occasion.id)
      assert groups.collect(&:id).include?(t.group.id)
    end
  end

  test "find event bookings" do
    event       = create(:event)
    event_n     = create(:event)
    groups      = create_list(:group, 2)

    create_list(:ticket, 4, event: event, group: groups.first,  state: :booked)
    create_list(:ticket, 4, event: event, group: groups.second, state: :booked)

    create(:ticket, event: event,   group: groups.first, state: :unbooked)
    create(:ticket, event: event_n, group: groups.first, state: :booked)

    bookings = Ticket.find_event_bookings(event.id, nil, 1)
    assert_equal 2, bookings.length
    bookings.each do |t|
      assert_equal 4, t.num_tickets.to_i
      assert groups.collect(&:id).include?(t.group.id)
    end

    # Filtered
    bookings = Ticket.find_event_bookings(event.id, { district_id: groups.first.school.district.id }, 1)
    assert_equal 1, bookings.length
    assert_equal groups.first.id, bookings.first.group_id
  end

  test "find occasion bookings" do
    occasion    = create(:occasion)
    occasion_n  = create(:occasion)
    groups      = create_list(:group, 2)

    create_list(:ticket, 4, occasion: occasion, group: groups.first,  state: :booked)
    create_list(:ticket, 4, occasion: occasion, group: groups.second, state: :booked)

    create(:ticket, occasion: occasion,   group: groups.first, state: :unbooked)
    create(:ticket, occasion: occasion_n, group: groups.first, state: :booked)

    bookings = Ticket.find_occasion_bookings(occasion.id, nil, 1)
    assert_equal 2, bookings.length
    bookings.each do |t|
      assert_equal 4, t.num_tickets.to_i
      assert groups.collect(&:id).include?(t.group.id)
    end

    # Filtered
    bookings = Ticket.find_occasion_bookings(occasion.id, { district_id: groups.first.school.district.id }, 1)
    assert_equal 1, bookings.length
    assert_equal groups.first.id, bookings.first.group_id
  end

  test "find group bookings" do
    group       = create(:group)
    group_n     = create(:group)
    occasions   = [
      create(:occasion, date: Date.today - 1),
      create(:occasion, date: Date.today - 2)
    ]

    create_list(:ticket, 4, occasion: occasions.first,  group: group, state: :booked)
    create_list(:ticket, 4, occasion: occasions.second, group: group, state: :booked)

    create(:ticket, occasion: occasions.first, group: group,   state: :unbooked)
    create(:ticket, occasion: occasions.first, group: group_n, state: :booked)

    bookings = Ticket.find_group_bookings(group, 1)
    assert_equal 2, bookings.length
    bookings.each do |t|
      assert_equal group.id, t.group.id
      assert_equal 4, t.num_tickets.to_i
      assert occasions.collect(&:id).include?(t.occasion.id)
    end
  end

  test "find booked" do
    group    = create(:group)
    occasion = create(:occasion)

    expected = [
      create(:ticket, group: group, occasion: occasion, state: :booked),
      create(:ticket, group: group, occasion: occasion, state: :deactivated)
    ].collect(&:id)

    create(:ticket, group: create(:group), occasion: occasion, state: :booked)
    create(:ticket, group: group, occasion: create(:occasion), state: :booked)
    create(:ticket, group: group, occasion: occasion,          state: :unbooked)

    assert_equal expected.sort, Ticket.find_booked(group, occasion).collect(&:id).sort
  end
  test "find not unbooked" do
    group    = create(:group)
    occasion = create(:occasion)

    expected = [
      create(:ticket, group: group, occasion: occasion, state: :booked),
      create(:ticket, group: group, occasion: occasion, state: :used),
      create(:ticket, group: group, occasion: occasion, state: :not_used),
      create(:ticket, group: group, occasion: occasion, state: :deactivated)
    ].collect(&:id)

    create(:ticket, group: create(:group), occasion: occasion, state: :booked)
    create(:ticket, group: group, occasion: create(:occasion), state: :booked)
    create(:ticket, group: group, occasion: occasion,          state: :unbooked)

    assert_equal expected.sort, Ticket.find_not_unbooked(group, occasion).collect(&:id).sort
  end
  test "find booked by type" do
    group    = create(:group)
    occasion = create(:occasion)

    normal     = create(:ticket, group: group, occasion: occasion, state: :booked)
    adult      = create(:ticket, group: group, occasion: occasion, state: :booked, adult: true)
    wheelchair = create(:ticket, group: group, occasion: occasion, state: :booked, wheelchair: true)

    [{}, {adult: true}, {wheelchair: true}].each do |o|
      create(:ticket, { group: group,          occasion: occasion,          state: :unbooked }.merge(o))
      create(:ticket, { group: create(:group), occasion: occasion,          state: :booked   }.merge(o))
      create(:ticket, { group: group,          occasion: create(:occasion), state: :booked   }.merge(o))
    end

    assert_equal [normal],     Ticket.find_booked_by_type(group, occasion, :normal)
    assert_equal [adult],      Ticket.find_booked_by_type(group, occasion, :adult)
    assert_equal [wheelchair], Ticket.find_booked_by_type(group, occasion, :wheelchair)
  end
  test "count by type state" do
    group    = create(:group)
    occasion = create(:occasion)

    [:booked, :used, :not_used].each do |s|
      create(:ticket, group: group, occasion: occasion, state: s)
      create(:ticket, group: group, occasion: occasion, state: s, adult: true)
      create(:ticket, group: group, occasion: occasion, state: s, wheelchair: true)
    end

    [{}, {adult: true}, {wheelchair: true}].each do |o|
      create(:ticket, { group: group,          occasion: occasion,          state: :unbooked }.merge(o))
      create(:ticket, { group: create(:group), occasion: occasion,          state: :booked   }.merge(o))
      create(:ticket, { group: group,          occasion: create(:occasion), state: :booked   }.merge(o))
    end

    assert_equal 3, Ticket.count_by_type_state(group, occasion, :normal)
    assert_equal 3, Ticket.count_by_type_state(group, occasion, :adult)
    assert_equal 3, Ticket.count_by_type_state(group, occasion, :wheelchair)
    assert_equal 2, Ticket.count_by_type_state(group, occasion, :normal,     [ :booked, :used ])
    assert_equal 2, Ticket.count_by_type_state(group, occasion, :adult,      [ :booked, :used ])
    assert_equal 2, Ticket.count_by_type_state(group, occasion, :wheelchair, [ :booked, :used ])
  end

  test "booking" do
    group    = create(:group)
    occasion = create(:occasion)

    [:booked, :used, :not_used].each do |s|
      create_list(:ticket, 3, group: group, occasion: occasion, state: s)
      create_list(:ticket, 4, group: group, occasion: occasion, state: s, adult: true)
      create_list(:ticket, 5, group: group, occasion: occasion, state: s, wheelchair: true)
    end

    [{}, {adult: true}, {wheelchair: true}].each do |o|
      create(:ticket, { group: group,          occasion: occasion,          state: :unbooked }.merge(o))
      create(:ticket, { group: create(:group), occasion: occasion,          state: :booked   }.merge(o))
      create(:ticket, { group: group,          occasion: create(:occasion), state: :booked   }.merge(o))
    end

    assert_equal({ normal: 9, adult: 12, wheelchair: 15 }, Ticket.booking(group, occasion))
  end
  test "usage" do
    group    = create(:group)
    occasion = create(:occasion)

    [:booked, :used, :not_used].each do |s|
      create_list(:ticket, 3, group: group, occasion: occasion, state: s)
      create_list(:ticket, 4, group: group, occasion: occasion, state: s, adult: true)
      create_list(:ticket, 5, group: group, occasion: occasion, state: s, wheelchair: true)
    end

    [{}, {adult: true}, {wheelchair: true}].each do |o|
      create(:ticket, { group: group,          occasion: occasion,          state: :unbooked }.merge(o))
      create(:ticket, { group: create(:group), occasion: occasion,          state: :booked   }.merge(o))
      create(:ticket, { group: group,          occasion: create(:occasion), state: :booked   }.merge(o))
    end

    assert_equal({ normal: 3, adult: 4, wheelchair: 5 }, Ticket.usage(group, occasion))
    assert_equal({ normal: nil, adult: nil, wheelchair: nil }, Ticket.usage(create(:group), occasion))
  end
end
