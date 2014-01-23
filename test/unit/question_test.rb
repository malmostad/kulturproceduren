# -*- encoding : utf-8 -*-
require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  test "validations" do
    question = build(:question, :question => "")
    assert !question.valid?
    assert question.errors.include?(:question)
  end

  test "statistics for answer forms" do
    # QuestionMark
    question     = create(:question, :qtype => "QuestionMark")
    answer_forms = create_list(:answer_form, 2)

    create(:answer, :question => question, :answer_form => answer_forms.first,  :answer_text => "2")
    create(:answer, :question => question, :answer_form => answer_forms.second, :answer_text => "3")

    result = question.statistics_for_answer_forms(answer_forms)
    assert_equal ["2.50"], result

    question_wo  = create(:question, :qtype => "QuestionMark")
    result = question_wo.statistics_for_answer_forms(answer_forms)
    assert_equal [0.0], result

    # QuestionText
    question     = create(:question, :qtype => "QuestionText")
    answer_forms = create_list(:answer_form, 2)

    create(:answer, :question => question, :answer_form => answer_forms.first,  :answer_text => "foo")
    create(:answer, :question => question, :answer_form => answer_forms.second, :answer_text => "bar")

    result = question.statistics_for_answer_forms(answer_forms)
    assert_equal ["foo", "bar"], result

    question_wo  = create(:question, :qtype => "QuestionText")
    result = question_wo.statistics_for_answer_forms(answer_forms)
    assert result.blank?

    # QuestionBool
    question     = create(:question, :qtype => "QuestionBool")
    answer_forms = create_list(:answer_form, 3)

    create(:answer, :question => question, :answer_form => answer_forms.first,  :answer_text => "y")
    create(:answer, :question => question, :answer_form => answer_forms.second, :answer_text => "n")
    create(:answer, :question => question, :answer_form => answer_forms.third,  :answer_text => "n")

    result = question.statistics_for_answer_forms(answer_forms)
    assert_equal ["33", "67"], result

    question_wo  = create(:question, :qtype => "QuestionBool")
    result = question_wo.statistics_for_answer_forms(answer_forms)
    assert_equal [0.0, 0.0], result

    # QuestionMchoice
    question     = create(:question, :qtype => "QuestionMchoice", :choice_csv => "foo,bar,baz")
    answer_forms = create_list(:answer_form, 3)

    create(:answer, :question => question, :answer_form => answer_forms.first,  :answer_text => "--- !map:HashWithIndifferentAccess \n\"foo\": \"1\"\n\"baz\": \"1\"\n")
    create(:answer, :question => question, :answer_form => answer_forms.second, :answer_text => "--- !map:HashWithIndifferentAccess \n\"baz\": \"1\"\n")
    create(:answer, :question => question, :answer_form => answer_forms.third,  :answer_text => "--- !map:HashWithIndifferentAccess \n\"baz\": \"1\"\n")

    result = question.statistics_for_answer_forms(answer_forms)
    assert_equal({ "foo" => 1, "baz" => 3, "bar" => 0}, result)

    question_wo  = create(:question, :qtype => "QuestionMchoice", :choice_csv => "foo,bar,baz")
    result = question_wo.statistics_for_answer_forms(answer_forms)
    assert_equal({ "foo" => 0, "baz" => 0, "bar" => 0}, result)
  end
end
