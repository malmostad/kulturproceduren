require 'test_helper'

class AllotmentTest < ActiveSupport::TestCase
  test "validations" do
    allotment = build(:allotment, :user => nil)
    assert !allotment.valid?
    assert_not_nil allotment.errors.on(:user)
    allotment = build(:allotment, :event => nil)
    assert !allotment.valid?
    assert_not_nil allotment.errors.on(:event)
  end
  test "synchronize tickets" do
    assert !Ticket.exists?
    group = create(:group)
    allotment = build(:allotment, :district => group.school.district, :group => group)
    assert allotment.save

    tickets = Ticket.all

    assert_equal allotment.amount, tickets.length
    tickets.each do |t|
      assert_equal allotment.event.id,    t.event.id
      assert_equal allotment.district.id, t.district.id
      assert_equal allotment.group.id,    t.group.id
      assert       t.unbooked?

      # Check for booleans, don't accept nil or empty string
      assert t.adult == false
      assert t.wheelchair == false
    end
  end
  test "allotment type" do
    group              = create(:group)
    group_allotment    = create(:allotment, :group => group)
    district_allotment = create(:allotment, :district => group.school.district)
    for_all_allotment  = create(:allotment)

    assert_equal :group,        group_allotment.allotment_type
    assert_equal :district,     district_allotment.allotment_type
    assert_equal :free_for_all, for_all_allotment.allotment_type
  end
  test "for group?" do
    group              = create(:group)
    group_allotment    = create(:allotment, :group => group)
    district_allotment = create(:allotment, :district => group.school.district)
    for_all_allotment  = create(:allotment)

    assert group_allotment.for_group?
    assert !district_allotment.for_group?
    assert !for_all_allotment.for_group?
  end
  test "for district?" do
    group              = create(:group)
    group_allotment    = create(:allotment, :group => group)
    district_allotment = create(:allotment, :district => group.school.district)
    for_all_allotment  = create(:allotment)

    assert !group_allotment.for_district?
    assert district_allotment.for_district?
    assert !for_all_allotment.for_district?
  end
  test "for all?" do
    group              = create(:group)
    group_allotment    = create(:allotment, :group => group)
    district_allotment = create(:allotment, :district => group.school.district)
    for_all_allotment  = create(:allotment)

    assert !group_allotment.for_all?
    assert !district_allotment.for_all?
    assert for_all_allotment.for_all?
  end
end
