# -*- encoding : utf-8 -*-
require 'test_helper'

class AnswerFormHelperTest < ActionView::TestCase
  test "get question fragment" do
    q = build(:question, qtype: "QuestionMark")
    assert_equal "answer_form/mark", get_question_fragment(q)
    q.qtype = "QuestionText"
    assert_equal "answer_form/text", get_question_fragment(q)
    q.qtype = "QuestionBool"
    assert_equal "answer_form/bool", get_question_fragment(q)
    q.qtype = "QuestionMchoice"
    assert_equal "answer_form/mchoice", get_question_fragment(q)
  end
end
