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
end
