require 'test_helper'

class QuestionaireTest < ActiveSupport::TestCase
  test "answered" do
    assert_equal [1, 2], questionaires(:pyjamassanger).answered
  end
end
