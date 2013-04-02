require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  test "unbook!" do
    booking = create(:booking)

    ticket = create(
      :ticket,
      :state       => Ticket::BOOKED,
      :booking     => booking,
      :user        => booking.user,
      :occasion    => booking.occasion,
      :wheelchair  => true,
      :adult       => true,
      :booked_when => Time.now
    )

    ticket.unbook!

    assert_equal Ticket::UNBOOKED, ticket.state
    assert_nil   ticket.booking
    assert_nil   ticket.user
    assert_nil   ticket.occasion
    assert       !ticket.wheelchair
    assert       !ticket.adult
    assert_nil   ticket.booked_when

    ticket = create(
      :ticket,
      :state       => Ticket::UNBOOKED,
      :booking     => booking,
      :user        => booking.user,
      :occasion    => booking.occasion,
      :wheelchair  => true,
      :adult       => true,
      :booked_when => Time.now
    )

    ticket.unbook!

    assert_equal     Ticket::UNBOOKED, ticket.state
    assert_not_nil   ticket.booking
    assert_not_nil   ticket.user
    assert_not_nil   ticket.occasion
    assert           ticket.wheelchair
    assert           ticket.adult
    assert_not_nil   ticket.booked_when
  end

  test "count wheelchair by occasion" do
    occasion = create(:occasion)
    create_list(:ticket, 10, :occasion => occasion, :state => Ticket::BOOKED,   :wheelchair => true)
    create_list(:ticket, 10, :occasion => occasion, :state => Ticket::USED,     :wheelchair => true)
    create_list(:ticket, 10, :occasion => occasion, :state => Ticket::NOT_USED, :wheelchair => true)

    create_list(:ticket, 1,  :occasion => occasion, :state => Ticket::BOOKED,   :wheelchair => false)
    create_list(:ticket, 1,  :occasion => occasion, :state => Ticket::UNBOOKED, :wheelchair => true)
    create_list(:ticket, 1,                         :state => Ticket::BOOKED,   :wheelchair => true)

    assert_equal 30, Ticket.count_wheelchair_by_occasion(occasion)
  end

  test "find user bookings" do
    user        = create(:user)
    user_n      = create(:user)
    groups      = create_list(:group, 2)
    occasions   = [
      create(:occasion, :date => Date.today - 1),
      create(:occasion, :date => Date.today - 2)
    ]

    create_list(:ticket, 4, :occasion => occasions.first,  :user => user, :group => groups.first,  :state => Ticket::BOOKED)
    create_list(:ticket, 4, :occasion => occasions.second, :user => user, :group => groups.first,  :state => Ticket::BOOKED)
    create_list(:ticket, 4, :occasion => occasions.first,  :user => user, :group => groups.second, :state => Ticket::BOOKED)
    create_list(:ticket, 4, :occasion => occasions.second, :user => user, :group => groups.second, :state => Ticket::BOOKED)

    create(:ticket, :occasion => occasions.first, :user => user,   :group => groups.first, :state => Ticket::UNBOOKED)
    create(:ticket, :occasion => occasions.first, :user => user_n, :group => groups.first, :state => Ticket::BOOKED)

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

    create_list(:ticket, 4, :event => event, :group => groups.first,  :state => Ticket::BOOKED)
    create_list(:ticket, 4, :event => event, :group => groups.second, :state => Ticket::BOOKED)

    create(:ticket, :event => event,   :group => groups.first, :state => Ticket::UNBOOKED)
    create(:ticket, :event => event_n, :group => groups.first, :state => Ticket::BOOKED)

    bookings = Ticket.find_event_bookings(event.id, nil, 1)
    assert_equal 2, bookings.length
    bookings.each do |t|
      assert_equal 4, t.num_tickets.to_i
      assert groups.collect(&:id).include?(t.group.id)
    end

    # Filtered
    bookings = Ticket.find_event_bookings(event.id, { :district_id => groups.first.school.district.id }, 1)
    assert_equal 1, bookings.length
    assert_equal groups.first.id, bookings.first.group_id
  end

  test "find occasion bookings" do
    occasion    = create(:occasion)
    occasion_n  = create(:occasion)
    groups      = create_list(:group, 2)

    create_list(:ticket, 4, :occasion => occasion, :group => groups.first,  :state => Ticket::BOOKED)
    create_list(:ticket, 4, :occasion => occasion, :group => groups.second, :state => Ticket::BOOKED)

    create(:ticket, :occasion => occasion,   :group => groups.first, :state => Ticket::UNBOOKED)
    create(:ticket, :occasion => occasion_n, :group => groups.first, :state => Ticket::BOOKED)

    bookings = Ticket.find_occasion_bookings(occasion.id, nil, 1)
    assert_equal 2, bookings.length
    bookings.each do |t|
      assert_equal 4, t.num_tickets.to_i
      assert groups.collect(&:id).include?(t.group.id)
    end

    # Filtered
    bookings = Ticket.find_occasion_bookings(occasion.id, { :district_id => groups.first.school.district.id }, 1)
    assert_equal 1, bookings.length
    assert_equal groups.first.id, bookings.first.group_id
  end

  test "find group bookings" do
    group       = create(:group)
    group_n     = create(:group)
    occasions   = [
      create(:occasion, :date => Date.today - 1),
      create(:occasion, :date => Date.today - 2)
    ]

    create_list(:ticket, 4, :occasion => occasions.first,  :group => group, :state => Ticket::BOOKED)
    create_list(:ticket, 4, :occasion => occasions.second, :group => group, :state => Ticket::BOOKED)

    create(:ticket, :occasion => occasions.first, :group => group,   :state => Ticket::UNBOOKED)
    create(:ticket, :occasion => occasions.first, :group => group_n, :state => Ticket::BOOKED)

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
      create(:ticket, :group => group, :occasion => occasion, :state => Ticket::BOOKED),
      create(:ticket, :group => group, :occasion => occasion, :state => Ticket::DEACTIVATED)
    ].collect(&:id)

    create(:ticket, :group => create(:group), :occasion => occasion, :state => Ticket::BOOKED)
    create(:ticket, :group => group, :occasion => create(:occasion), :state => Ticket::BOOKED)
    create(:ticket, :group => group, :occasion => occasion,          :state => Ticket::UNBOOKED)

    assert_equal expected.sort, Ticket.find_booked(group, occasion).collect(&:id).sort
  end
  test "find not unbooked" do
    group    = create(:group)
    occasion = create(:occasion)

    expected = [
      create(:ticket, :group => group, :occasion => occasion, :state => Ticket::BOOKED),
      create(:ticket, :group => group, :occasion => occasion, :state => Ticket::USED),
      create(:ticket, :group => group, :occasion => occasion, :state => Ticket::NOT_USED),
      create(:ticket, :group => group, :occasion => occasion, :state => Ticket::DEACTIVATED)
    ].collect(&:id)

    create(:ticket, :group => create(:group), :occasion => occasion, :state => Ticket::BOOKED)
    create(:ticket, :group => group, :occasion => create(:occasion), :state => Ticket::BOOKED)
    create(:ticket, :group => group, :occasion => occasion,          :state => Ticket::UNBOOKED)

    assert_equal expected.sort, Ticket.find_not_unbooked(group, occasion).collect(&:id).sort
  end
  test "find booked by type" do
    group    = create(:group)
    occasion = create(:occasion)

    normal     = create(:ticket, :group => group, :occasion => occasion, :state => Ticket::BOOKED)
    adult      = create(:ticket, :group => group, :occasion => occasion, :state => Ticket::BOOKED, :adult => true)
    wheelchair = create(:ticket, :group => group, :occasion => occasion, :state => Ticket::BOOKED, :wheelchair => true)

    [{}, {:adult => true}, {:wheelchair => true}].each do |o|
      create(:ticket, { :group => group,          :occasion => occasion,          :state => Ticket::UNBOOKED }.merge(o))
      create(:ticket, { :group => create(:group), :occasion => occasion,          :state => Ticket::BOOKED   }.merge(o))
      create(:ticket, { :group => group,          :occasion => create(:occasion), :state => Ticket::BOOKED   }.merge(o))
    end

    assert_equal [normal],     Ticket.find_booked_by_type(group, occasion, :normal)
    assert_equal [adult],      Ticket.find_booked_by_type(group, occasion, :adult)
    assert_equal [wheelchair], Ticket.find_booked_by_type(group, occasion, :wheelchair)
  end
  test "count by type state" do
    group    = create(:group)
    occasion = create(:occasion)

    [Ticket::BOOKED, Ticket::USED, Ticket::NOT_USED].each do |s|
      create(:ticket, :group => group, :occasion => occasion, :state => s)
      create(:ticket, :group => group, :occasion => occasion, :state => s, :adult => true)
      create(:ticket, :group => group, :occasion => occasion, :state => s, :wheelchair => true)
    end

    [{}, {:adult => true}, {:wheelchair => true}].each do |o|
      create(:ticket, { :group => group,          :occasion => occasion,          :state => Ticket::UNBOOKED }.merge(o))
      create(:ticket, { :group => create(:group), :occasion => occasion,          :state => Ticket::BOOKED   }.merge(o))
      create(:ticket, { :group => group,          :occasion => create(:occasion), :state => Ticket::BOOKED   }.merge(o))
    end

    assert_equal 3, Ticket.count_by_type_state(group, occasion, :normal)
    assert_equal 3, Ticket.count_by_type_state(group, occasion, :adult)
    assert_equal 3, Ticket.count_by_type_state(group, occasion, :wheelchair)
    assert_equal 2, Ticket.count_by_type_state(group, occasion, :normal,     [ Ticket::BOOKED, Ticket::USED ])
    assert_equal 2, Ticket.count_by_type_state(group, occasion, :adult,      [ Ticket::BOOKED, Ticket::USED ])
    assert_equal 2, Ticket.count_by_type_state(group, occasion, :wheelchair, [ Ticket::BOOKED, Ticket::USED ])
  end

  test "booking" do
    group    = create(:group)
    occasion = create(:occasion)

    [Ticket::BOOKED, Ticket::USED, Ticket::NOT_USED].each do |s|
      create_list(:ticket, 3, :group => group, :occasion => occasion, :state => s)
      create_list(:ticket, 4, :group => group, :occasion => occasion, :state => s, :adult => true)
      create_list(:ticket, 5, :group => group, :occasion => occasion, :state => s, :wheelchair => true)
    end

    [{}, {:adult => true}, {:wheelchair => true}].each do |o|
      create(:ticket, { :group => group,          :occasion => occasion,          :state => Ticket::UNBOOKED }.merge(o))
      create(:ticket, { :group => create(:group), :occasion => occasion,          :state => Ticket::BOOKED   }.merge(o))
      create(:ticket, { :group => group,          :occasion => create(:occasion), :state => Ticket::BOOKED   }.merge(o))
    end

    assert_equal({ :normal => 9, :adult => 12, :wheelchair => 15 }, Ticket.booking(group, occasion))
  end
  test "usage" do
    group    = create(:group)
    occasion = create(:occasion)

    [Ticket::BOOKED, Ticket::USED, Ticket::NOT_USED].each do |s|
      create_list(:ticket, 3, :group => group, :occasion => occasion, :state => s)
      create_list(:ticket, 4, :group => group, :occasion => occasion, :state => s, :adult => true)
      create_list(:ticket, 5, :group => group, :occasion => occasion, :state => s, :wheelchair => true)
    end

    [{}, {:adult => true}, {:wheelchair => true}].each do |o|
      create(:ticket, { :group => group,          :occasion => occasion,          :state => Ticket::UNBOOKED }.merge(o))
      create(:ticket, { :group => create(:group), :occasion => occasion,          :state => Ticket::BOOKED   }.merge(o))
      create(:ticket, { :group => group,          :occasion => create(:occasion), :state => Ticket::BOOKED   }.merge(o))
    end

    assert_equal({ :normal => 3, :adult => 4, :wheelchair => 5 }, Ticket.usage(group, occasion))
    assert_equal({ :normal => nil, :adult => nil, :wheelchair => nil }, Ticket.usage(create(:group), occasion))
  end
end
