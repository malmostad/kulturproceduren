require 'test_helper'

class QuestionsHelperTest < ActionView::TestCase
  include ERB::Util

  test "question statistics" do
    question = build(:question, qtype: "dummy")
    assert_equal "", question_statistics(question, nil)

    question.qtype = "QuestionMark"
    assert_equal "Genomsnitt = 4.5", question_statistics(question, [4.5, 6.6])

    question.qtype = "QuestionText"
    assert_equal "<ul><li>foo</li><li>1.1</li></ul>", question_statistics(question, ["foo", nil, "", 1.1])

    question.qtype = "QuestionBool"
    assert_equal "Ja 33.3% , Nej 66.7%", question_statistics(question, [33.3, 66.7])

    question.qtype = "QuestionMchoice"
    assert_equal "<table id=\"kp-mchoice-stat\"><thead><tr><th>apa</th><th>bepa</th><th>cepa</th></tr></thead><tbody><tr><td>1.1</td><td>2.2</td><td>3.3</td></tr></tbody></table>",
      question_statistics(question, {
        "cepa" => 3.3,
        "apa"  => 1.1,
        "bepa" => 2.2
      })
  end
end
