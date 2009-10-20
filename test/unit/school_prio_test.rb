require 'test_helper'

class SchoolPrioTest < ActiveSupport::TestCase
  test "lowest prio" do
    assert_equal school_prios(:syd_prio4).prio, SchoolPrio.lowest_prio(districts(:syd))
  end

  test "highest prio" do
    assert_equal school_prios(:syd_prio1).prio, SchoolPrio.highest_prio(districts(:syd))
  end
end
