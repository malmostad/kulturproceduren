require_relative '../test_helper'

class BookingRequirementTest < ActiveSupport::TestCase
  test "get" do
    group = create(:group)
    occasion = create(:occasion)

    booking_requirement = create(:booking_requirement, group: group, occasion: occasion)

    # dummies
    create(:booking_requirement)
    create(:booking_requirement, group: group)
    create(:booking_requirement, occasion: occasion)

    assert_equal booking_requirement.id, BookingRequirement.get(group, occasion).id
  end
end
