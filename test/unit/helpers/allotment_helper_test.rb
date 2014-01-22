# -*- encoding : utf-8 -*-
require 'test_helper'

class AllotmentHelperTest < ActionView::TestCase
  test "fill indicator" do
    assert_equal "partial", fill_indicator(10, 5)
    assert_equal "full", fill_indicator(10, 10)
    assert_nil fill_indicator(0, 0)
    assert_nil fill_indicator(-1, 0)
  end

  test "fill indicator text" do
    full = fill_indicator_text(10, 10)
    partial = fill_indicator_text(10, 5)
    zero = fill_indicator_text(0, 0)

    assert_not_equal full, partial
    assert_not_equal zero, partial
    assert_not_equal zero, full
    assert_equal zero, fill_indicator_text(-1, 0)
  end
end
