require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  test "count wheelchair by occasion" do
    assert_equal 1, Ticket.count_wheelchair_by_occasion(occasions(:pyjamassanger_new))
  end

  test "find user bookings" do
    bookings = Ticket.find_user_bookings(users(:pelle), 1)

    assert !bookings.empty?

    bookings.each do |booking|
      assert_equal users(:pelle).id, booking[:user_id]
    end
  end

  test "find group bookings" do
    bookings = Ticket.find_group_bookings(groups(:ostskolan1_klass1), 1)

    assert !bookings.empty?

    bookings.each do |booking|
      assert_equal groups(:ostskolan1_klass1).id, booking[:group_id]
    end
  end

  test "find booked" do
    ts = Ticket.find_booked(groups(:nordskolan1_klass1), occasions(:bla_film1))
    assert !ts.empty?

    ts.each do |t|
      assert_equal groups(:nordskolan1_klass1).id, t.group_id
      assert_equal occasions(:bla_film1).id, t.occasion_id
      assert_equal Ticket::BOOKED, t.state
    end
  end

  test "find not unbooked" do
    ts = Ticket.find_not_unbooked(groups(:nordskolan1_klass1), occasions(:bla_film1))
    assert !ts.empty?

    ts.each do |t|
      assert_equal groups(:nordskolan1_klass1).id, t.group_id
      assert_equal occasions(:bla_film1).id, t.occasion_id
      assert_not_equal Ticket::UNBOOKED, t.state
    end
  end

  test "find booked by type" do
    g = groups(:nordskolan1_klass1)
    o = occasions(:bla_film1)

    [:normal, :wheelchair, :adult].each do |type|
      ts = Ticket.find_booked_by_type(g, o, type)

      assert !ts.empty?

      ts.each do |t|
        assert_equal g.id, t.group_id
        assert_equal o.id, t.occasion_id
        assert_equal Ticket::BOOKED, t.state

        case type
        when :normal
          assert !t.adult
          assert !t.wheelchair
        when :wheelchair
          assert t.wheelchair
        when :adult
          assert t.adult
        end
      end
    end
  end

  test "count by type state" do
    g = groups(:nordskolan1_klass1)
    o = occasions(:bla_film1)

    assert_equal 3, Ticket.count_by_type_state(g, o, :normal)
    assert_equal 1, Ticket.count_by_type_state(g, o, :adult)
    assert_equal 1, Ticket.count_by_type_state(g, o, :wheelchair)
    assert_equal 1, Ticket.count_by_type_state(g, o, :normal, Ticket::BOOKED)
  end

  test "booking" do
    g = groups(:nordskolan1_klass1)
    o = occasions(:bla_film1)
    b = Ticket.booking(g, o)
    assert_equal 3, b[:normal]
    assert_equal 1, b[:wheelchair]
    assert_equal 1, b[:adult]
  end

  test "usage" do
    g = groups(:nordskolan1_klass1)
    o = occasions(:bla_film1)
    u = Ticket.usage(g, o)
    assert_equal 1, u[:normal]
    assert_nil u[:wheelchair]
    assert_nil u[:adult]
  end
end
