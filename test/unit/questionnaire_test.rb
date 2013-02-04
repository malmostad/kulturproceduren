require 'test_helper'

class QuestionnaireTest < ActiveSupport::TestCase
  test "answered" do
    assert_equal [1, 2], questionnaires(:pyjamassanger).answered
  end
end
