require 'test_helper'

class BookingRequirementTest < ActiveSupport::TestCase
  test "get" do
    assert_equal booking_requirements(:ostskolan1_for_rc_group).id,
      BookingRequirement.get(groups(:ostskolan1_klass1), occasions(:roda_cirkusen_group_past)).id
  end
end
