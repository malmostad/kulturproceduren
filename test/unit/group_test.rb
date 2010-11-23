require 'test_helper'

class GroupTest < ActiveSupport::TestCase

  test "number of children by age span" do
    g = Group.find groups(:centrumskolan1_klass35).id

    num = g.age_groups.num_children_by_age_span(9, 10)
    assert_equal age_groups(:centrumskolan1_klass_35_9).quantity + age_groups(:centrumskolan1_klass_35_10).quantity, num
    num = g.age_groups.num_children_by_age_span(10, 10)
    assert_equal age_groups(:centrumskolan1_klass_35_10).quantity, num
    num = g.age_groups.num_children_by_age_span(1, 2)
    assert_equal 0, num
  end

  test "total children" do
    assert_equal age_groups(:centrumskolan1_klass_35_9).quantity +
      age_groups(:centrumskolan1_klass_35_10).quantity +
      age_groups(:centrumskolan1_klass_35_11).quantity,
      groups(:centrumskolan1_klass35).total_children
  end

  test "companion by occasion" do
    assert_equal companions(:bengt).id,
      groups(:ostskolan1_klass1).companion_by_occasion(occasions(:roda_cirkusen_group_past)).id
  end

  test "booked_tickets_by_occasion" do
    assert_equal 1,
      groups(:ostskolan1_klass1).booked_tickets_by_occasion(occasions(:roda_cirkusen_group_past))
  end

  test "available tickets by occasion" do
    assert_equal 1, groups(:ostskolan1_klass1).available_tickets_by_occasion(occasions(:roda_cirkusen_group_past))
    assert_equal 0, groups(:ostskolan1_klass1).available_tickets_by_occasion(occasions(:roda_cirkusen_group_past), Ticket::UNBOOKED, true)
    assert_equal 0, groups(:sydskolan1_klass1).available_tickets_by_occasion(occasions(:roda_cirkusen_group_past))
    assert_equal 2, groups(:ostskolan1_klass1).available_tickets_by_occasion(occasions(:roda_cirkusen_district_past))
    assert_equal 0, groups(:sydskolan1_klass1).available_tickets_by_occasion(occasions(:roda_cirkusen_district_past))
    assert_equal 2, groups(:ostskolan1_klass1).available_tickets_by_occasion(occasions(:roda_cirkusen_ffa_past))
    assert_equal 2, groups(:sydskolan1_klass1).available_tickets_by_occasion(occasions(:roda_cirkusen_ffa_past))
  end

  test "bookable tickets" do
    # Group allotment
    ts = groups(:ostskolan1_klass1).bookable_tickets(occasions(:roda_cirkusen_group_past))
    assert_equal 1, ts.length
    assert_equal occasions(:roda_cirkusen_group_past).event.id, ts[0].event_id
    assert_equal groups(:ostskolan1_klass1).id, ts[0].group_id
    # District allotment
    ts = groups(:ostskolan1_klass1).bookable_tickets(occasions(:roda_cirkusen_district_past))
    assert_equal 2, ts.length
    ts.each do |t|
      assert_equal occasions(:roda_cirkusen_district_past).event.id, t.event_id
      assert_equal groups(:ostskolan1_klass1).school.district_id, t.district_id
    end
    # FFA allotment
    ts = groups(:sydskolan1_klass1).bookable_tickets(occasions(:roda_cirkusen_ffa_past))
    assert_equal 2, ts.length
    ts.each do |t|
      assert_equal occasions(:roda_cirkusen_ffa_past).event.id, t.event_id
    end
  end

  test "move first in prio" do
    g = Group.find groups(:centrumskolan2_klass6).id
    g.move_first_in_prio
    assert_equal 1, g.priority
    assert_equal 2, Group.find(groups(:centrumskolan1_klass35).id).priority
    assert_equal 8, Group.find(groups(:sydskolan1_klass1).id).priority
  end
  test "move last in prio" do
    g = Group.find groups(:centrumskolan2_klass6).id
    g.move_last_in_prio
    assert_equal Group.count(:all), g.priority
    assert_equal 5, Group.find(groups(:ostskolan1_klass1).id).priority
    assert_equal 1, Group.find(groups(:centrumskolan1_klass35).id).priority
  end
  test "default priority" do
    g = Group.new
    g.name = "Test"
    g.school = schools(:centrumskolan1)
    assert g.save
    assert_equal 12, g.priority
  end
end
