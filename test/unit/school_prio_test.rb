require 'test_helper'

class SchoolPrioTest < ActiveSupport::TestCase
  test "lowest prio" do
    assert_equal school_prios(:fp5p).prio, SchoolPrio.lowest_prio(districts(:for_prio_testing))
  end

  test "highest prio" do
    assert_equal school_prios(:fp1p).prio, SchoolPrio.highest_prio(districts(:for_prio_testing))
  end
end
