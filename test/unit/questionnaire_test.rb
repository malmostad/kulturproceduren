# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class QuestionnaireTest < ActiveSupport::TestCase
  test "for event" do
    create_list(:questionnaire, 5, :target_cd => 1)
    create_list(:questionnaire, 5, :target_cd => 2)
    Questionnaire.for_event.each { |q| assert q.for_event? }
  end
  test "for unbooking" do
    create_list(:questionnaire, 5, :target_cd => 1)
    create_list(:questionnaire, 5, :target_cd => 2)
    Questionnaire.for_unbooking.each { |q| assert q.for_unbooking? }
  end
  test "answered" do
    questionnaire = create(:questionnaire)
    create_list(:answer_form, 9, :questionnaire => questionnaire, :completed => true)
    create_list(:answer_form, 7, :questionnaire => questionnaire, :completed => false)
    answered, not_answered = questionnaire.answered
    assert_equal 9, answered
    assert_equal 7, not_answered
  end
  test "find unbooking, not existing" do
    assert_nil Questionnaire.for_unbooking.first
    unbooking = Questionnaire.find_unbooking
    assert unbooking.for_unbooking?
    assert_not_nil Questionnaire.for_unbooking.first
  end
  test "find unbooking, existing" do
    questionnaire = create(:questionnaire, :target_cd => 2)
    unbooking = Questionnaire.find_unbooking
    assert_equal questionnaire.id, unbooking.id
  end
end
