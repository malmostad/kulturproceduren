require_relative '../../test_helper'

class QuestionsHelperTest < ActionView::TestCase
  include ERB::Util

  test "question statistics" do
    question = build(:question, qtype: "dummy")
    assert_equal "", question_statistics(question, nil)

    question.qtype = "QuestionMark"
    assert_equal "<table><tr><th>Genomsnitt</th><td>4.5</td></tr></table>",
      question_statistics(question, [4.5, 6.6])

    question.qtype = "QuestionText"
    assert_equal "<table><tr><td>foo</td></tr><tr><td>1.1</td></tr></table>",
      question_statistics(question, ["foo", nil, "", 1.1])

    question.qtype = "QuestionBool"
    assert_equal "<table><tr><th>Ja</th><td>33.3%</td></tr><tr><th>Nej</th><td>66.7%</td></tr></table>",
      question_statistics(question, [33.3, 66.7])

    question.qtype = "QuestionMchoice"
    assert_equal "<table><tr><th>apa</th><td>1.1</td></tr><tr><th>bepa</th><td>2.2</td></tr><tr><th>cepa</th><td>3.3</td></tr></table>",
      question_statistics(question, {
        "cepa" => 3.3,
        "apa"  => 1.1,
        "bepa" => 2.2
      })
  end
end
