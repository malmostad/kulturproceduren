require 'test_helper'

class CompanionTest < ActiveSupport::TestCase
  test "get" do
    assert_equal companions(:bengt).id,
      Companion.get(groups(:ostskolan1_klass1), occasions(:roda_cirkusen_group_past)).id
  end
end
