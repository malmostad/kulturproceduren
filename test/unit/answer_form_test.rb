# -*- encoding : utf-8 -*-
require 'test_helper'

class AnswerFormTest < ActiveSupport::TestCase
  test "generate id" do
    answer_form = AnswerForm.new
    answer_form.save
    assert answer_form.id =~ /^[A-Za-z0-9]{45}$/
  end

  test "valid answer?" do
    mandatory     = create_list(:question, 2, :mandatory => true)
    regular       = create_list(:question, 2)
    questionnaire = create(:questionnaire, :questions => mandatory + regular)
    answer_form   = create(:answer_form,   :questionnaire => questionnaire)

    mandatory_ids = mandatory.collect(&:id)
    regular_ids   = regular.collect(&:id)

    assert !answer_form.valid_answer?({})

    # Generate an answer hash: { question_id => "answer", question_id => "answer" ... }
    answer = Hash[(mandatory_ids + regular_ids).zip(["foo"]*4)]

    # All answered
    assert answer_form.valid_answer?(answer)

    # Missing regular
    answer.delete(regular_ids.first)
    assert answer_form.valid_answer?(answer)

    # Missing mandatory
    answer[mandatory_ids.first] = ""
    assert !answer_form.valid_answer?(answer)
    answer.delete(mandatory_ids.first)
    assert !answer_form.valid_answer?(answer)
  end

  test "answer" do
    mandatory     = create_list(:question, 2, :mandatory => true)
    regular       = create_list(:question, 2)
    questionnaire = create(:questionnaire, :questions    => mandatory + regular)
    answer_form   = create(:answer_form, :questionnaire  => questionnaire)
    # Generate an answer hash: { question_id => "answer", question_id => "answer" ... }
    answer        = Hash[(mandatory.collect(&:id) + regular.collect(&:id)).zip(["foo"]*4)]

    assert !answer_form.answer({})
    assert !answer_form.completed

    assert answer_form.answer(answer)
    assert answer_form.completed
    assert_equal 4, answer_form.answers.length
    answer_form.answers.each { |a| assert_equal "foo", a.answer_text }
  end

  test "find_overdue" do
    regular    = create(:occasion, :date => Date.today - 10)
    wrong_date = create(:occasion, :date => Date.today - 5)
    cancelled  = create(:occasion, :date => Date.today - 10, :cancelled => true)

    create_list(:answer_form, 10, :occasion => regular)
    create(:answer_form, :occasion => regular, :completed => true)
    create(:answer_form, :occasion => wrong_date)
    create(:answer_form, :occasion => cancelled)

    result = AnswerForm.find_overdue(Date.today - 10)
    assert_equal 10, result.length
    result.each { |af| assert !af.completed && af.occasion.date = Date.today - 10 && !af.occasion.cancelled }
  end
end
