require_relative '../test_helper'

class SchoolTest < ActiveSupport::TestCase
  test "validations" do
    school = build(:school, name: "")
    assert !school.valid?
    assert school.errors.include?(:name)
    school = build(:school, district: nil)
    assert !school.valid?
    assert school.errors.include?(:district)
  end

  test "groups by age span" do
    school = create(:school)
    create(:school_with_age_groups) # dummy

    7.upto(12).collect { |i| create(:group_with_age_groups, school: school, _age_group_data: [[i, 1]]) }

    groups = school.groups.find_by_age_span(8, 11)
    assert !groups.blank?
    groups.each { |g| assert g.age_groups.exists?(age: (8..11))}

    create(:group_with_age_groups, school: school, _age_group_data: [[1, 1]], active: false)
    assert school.groups.find_by_age_span(1, 2).blank?
  end

  test "available tickets by occasion" do
    occasion = create(:occasion)
    school   = create(:school)
    groups   = create_list(:group, 5, school: school)

    groups.each do |g|
      create_list(:ticket, 3, occasion: occasion, event: occasion.event, group: g, district: school.district, state: :unbooked)
      create(:ticket,         occasion: occasion, event: occasion.event, group: g, district: school.district, state: :booked)
    end

    create_list(:ticket, 5, occasion: occasion, event: occasion.event, district: school.district, state: :unbooked)
    create_list(:ticket, 5, occasion: occasion, event: occasion.event,                               state: :unbooked)

    create(:ticket, occasion: occasion, event: occasion.event,                               state: :booked)
    create(:ticket, occasion: occasion, event: occasion.event, district: school.district, state: :booked)

    occasion.event.ticket_state = :alloted_group
    assert_equal 15, school.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :alloted_district
    assert_equal 20, school.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :free_for_all
    assert_equal 25, school.available_tickets_by_occasion(occasion)
  end

  test "find with tickets to events" do
    events = create_list(:event, 2)

    with = create_list(:school, 5)

    with.each do |s|
      create_list(:group, 5, school: s).each do |g|
        create_list(:ticket, 5, group: g, event: events.first)
      end
    end

    create_list(:school, 4).each do |s|
      create_list(:group, 4, school: s).each do |g|
        create_list(:ticket, 4, group: g, event: events.second)
      end
    end

    with_ids = with.collect(&:id)

    School.find_with_tickets_to_event_for_all_groups(events.first).each do |s|
      assert with_ids.include?(s.id)
    end
  end

  test "active" do
    active = create(:school)
    inactive = create(:school)

    inactive.school_type.active = false
    inactive.school_type.save

    assert_equal [active], School.active
  end

  test "name_search" do
    school1 = create(:school, name: "foo")
    school2 = create(:school, name: "bar")

    # Normal
    assert_equal [school1], School.name_search("foo")
    # Case insensitive
    assert_equal [school1], School.name_search("FOO")
    # Wildcard
    assert_equal [school1], School.name_search("%o%")
  end
end
