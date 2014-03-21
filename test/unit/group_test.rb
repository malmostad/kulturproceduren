# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class GroupTest < ActiveSupport::TestCase
  test "validations" do
    group = build(:group, :name => "")
    assert !group.valid?
    assert group.errors.include?(:name)
    group = build(:group, :school => nil)
    assert !group.valid?
    assert group.errors.include?(:school)
  end

  test "age group, number of children by age span" do
    group = create(:group_with_age_groups, :age_group_data => [[9, 10], [10,10], [11,20], [12,15]])

    assert_equal 10+20, group.age_groups.num_children_by_age_span(10, 11)
    assert_equal 15,    group.age_groups.num_children_by_age_span(12, 13)
    assert_equal 0,     group.age_groups.num_children_by_age_span(1,  1)
  end

  test "booking requirements, for occasion" do
    occasion = create(:occasion)
    group = create(:group)
    booking_requirement = create(:booking_requirement, :group => group, :occasion => occasion)
    create(:booking_requirement, :group => group)
    create(:booking_requirement, :occasion => occasion)

    assert_equal booking_requirement.id, group.booking_requirements.for_occasion(occasion).id
  end

  test "total children" do
    group = create(:group_with_age_groups, :age_group_data => [[9, 10], [10,10], [11,20], [12,15]])
    create(:group_with_age_groups) # dummy
    assert_equal 10+10+20+15, group.total_children
  end

  test "booked tickets by occasion" do
    group = create(:group)
    occasion = create(:occasion)
    create_list(:ticket, 5, :group => group,       :occasion => occasion,    :state => :unbooked)
    create_list(:ticket, 6, :group => group,       :occasion => occasion,    :state => :booked)
    create_list(:ticket, 4, :occasion => occasion,                           :state => :booked)

    assert_equal 6, group.booked_tickets_by_occasion(occasion)
    assert_equal 6, group.booked_tickets_by_occasion(occasion.id)
  end

  test "available tickets by occasion" do
    group = create(:group)
    occasion = create(:occasion, :seats => 40)
    event = occasion.event

    create_list(:ticket, 10, :group => group, :district => group.school.district, :event => event, :state => :unbooked)
    create_list(:ticket, 10,                  :district => group.school.district, :event => event, :state => :unbooked)
    create_list(:ticket, 10,                                                      :event => event, :state => :unbooked)

    create(:ticket, :group => group, :district => group.school.district, :occasion => occasion, :event => event, :state => :booked)
    create(:ticket,                                                      :occasion => occasion, :event => event, :state => :booked)
    create(:ticket,                  :district => group.school.district, :occasion => occasion, :event => event, :state => :booked)

    # Without deactivated
    occasion.event.ticket_state = :alloted_group
    assert_equal 10, group.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :alloted_district
    assert_equal 20, group.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :free_for_all
    assert_equal 30, group.available_tickets_by_occasion(occasion)
    
    # With deactivated
    create_list(:ticket, 5, :group => group, :district => group.school.district, :event => event, :state => :deactivated)
    occasion.event.ticket_state = :alloted_group
    assert_equal 15, group.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :alloted_district
    assert_equal 20, group.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :free_for_all
    assert_equal 30, group.available_tickets_by_occasion(occasion)

    # Limited by seats
    occasion.seats = 2
    occasion.event.ticket_state = :alloted_group
    assert_equal 2, group.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :alloted_district
    assert_equal 2, group.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :free_for_all
    assert_equal 2, group.available_tickets_by_occasion(occasion)
  end

  test "bookable tickets" do
    group = create(:group)
    occasion = create(:occasion, :seats => 40)
    event = occasion.event

    create_list(:ticket, 10, :group => group, :district => group.school.district, :event => event, :state => :unbooked)
    create_list(:ticket, 5 , :group => group, :district => group.school.district, :event => event, :state => :deactivated)
    create_list(:ticket, 10,                  :district => group.school.district, :event => event, :state => :unbooked)
    create_list(:ticket, 10,                                                      :event => event, :state => :unbooked)

    create(:ticket, :group => group, :district => group.school.district, :occasion => occasion, :event => event, :state => :booked)
    create(:ticket,                                                      :occasion => occasion, :event => event, :state => :booked)
    create(:ticket,                  :district => group.school.district, :occasion => occasion, :event => event, :state => :booked)

    occasion.event.ticket_state = :alloted_group
    tickets = group.bookable_tickets(occasion)
    assert_equal 15, tickets.length
    occasion.event.ticket_state = :alloted_district
    tickets = group.bookable_tickets(occasion)
    assert_equal 20, tickets.length
    occasion.event.ticket_state = :free_for_all
    tickets = group.bookable_tickets(occasion)
    assert_equal 30, tickets.length
  end

  test "move first in prio" do
    groups = 1.upto(3).collect { |i| create(:group, :priority => i) }

    groups.third.move_first_in_prio
    groups.map(&:reload)

    assert_equal 1, groups.third.priority
    assert_equal 2, groups.first.priority
    assert_equal 3, groups.second.priority
  end
  test "move multiple first in prio" do
    groups = 1.upto(5).collect { |i| create(:group, :priority => i) }

    groups.third.move_first_in_prio
    groups.fifth.move_first_in_prio
    groups.map(&:reload)

    assert_equal 1, groups.fifth.priority
    assert_equal 2, groups.third.priority
    assert_equal 3, groups.first.priority
    assert_equal 4, groups.second.priority
    assert_equal 5, groups.fourth.priority
  end
  test "move last in prio" do
    groups = 1.upto(3).collect { |i| create(:group, :priority => i) }

    groups.first.move_last_in_prio
    groups.map(&:reload)

    assert_equal 1, groups.second.priority
    assert_equal 2, groups.third.priority
    assert_equal 3, groups.first.priority
  end
  test "move multiple last in prio" do
    groups = 1.upto(5).collect { |i| create(:group, :priority => i) }

    groups.third.move_last_in_prio
    groups.first.move_last_in_prio
    groups.map(&:reload)

    assert_equal 1, groups.second.priority
    assert_equal 2, groups.fourth.priority
    assert_equal 3, groups.fifth.priority
    assert_equal 4, groups.third.priority
    assert_equal 5, groups.first.priority
  end
  test "default priority" do
    school = create(:school_with_groups)
    create(:school_with_groups) # dummy

    group = Group.new
    group.name = "Test"
    group.school = school
    assert group.save
    assert_equal Group.count(:all), group.priority
  end

  test "sort ids by priority" do
    groups = 10.downto(1).collect { |i| create(:group, :priority => i) }
    sorted_ids = Group.sort_ids_by_priority(groups.collect(&:id))
    
    last_prio = 0
    sorted_ids.each do |id|
      prio = Group.find(id).priority
      assert last_prio < prio
      last_prio = prio
    end
  end
end
