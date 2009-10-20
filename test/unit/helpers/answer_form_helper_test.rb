require 'test_helper'

class AnswerFormHelperTest < ActionView::TestCase
  test "get question fragment" do
    q = Question.new { |q| q.qtype = "QuestionMark" }
    assert_equal "mark", get_question_fragment(q)
    q.qtype = "QuestionText"
    assert_equal "text", get_question_fragment(q)
    q.qtype = "QuestionBool"
    assert_equal "bool", get_question_fragment(q)
    q.qtype = "QuestionMchoice"
    assert_equal "mchoice", get_question_fragment(q)
  end
end
