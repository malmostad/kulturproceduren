require_relative '../test_helper'

class AnswerFormControllerTest < ActionController::TestCase
  test "submit not existing" do
    post :submit, answer_form_id: "not_exist"
    assert_redirected_to root_url()
    assert_equal         "Ogiltig utvärderingsenkät", flash[:error]
  end
  test "submit completed" do
    answer_form = create(:answer_form, completed: true)
    post :submit, answer_form_id: answer_form.id
    assert_redirected_to root_url()
    assert_equal         "Utvärderingsenkäten är redan besvarad", flash[:error]
  end
  test "submit no answers" do
    answer_form = create(:answer_form)
    get :submit, answer_form_id: answer_form.id
    assert_response :success
  end
  test "submit some answers" do
    mandatory     = create_list(:question, 2, mandatory: true)
    regular       = create_list(:question, 2)
    questionnaire = create(:questionnaire, questions: mandatory + regular)
    answer_form   = create(:answer_form, questionnaire: questionnaire)
    # Generate an answer hash: { question_id => "answer", question_id => "answer" ... }
    answer        = Hash[regular.collect(&:id).zip(["foo"]*2)]

    post :submit, answer_form_id: answer_form, answer: answer
    assert_response :success
  end
  test "submit all answers" do
    mandatory     = create_list(:question, 2, mandatory: true)
    regular       = create_list(:question, 2)
    questionnaire = create(:questionnaire, questions: mandatory + regular)
    answer_form   = create(:answer_form, questionnaire: questionnaire)
    # Generate an answer hash: { question_id => "answer", question_id => "answer" ... }
    answer        = Hash[(mandatory.collect(&:id) + regular.collect(&:id)).zip(["foo"]*4)]

    post :submit, answer_form_id: answer_form, answer: answer
    assert_redirected_to root_url()
    assert_equal         "Tack för att du svarade på utvärderingsenkäten", flash[:notice]

    answer_form.reload
    assert answer_form.completed
    answer_form.answers(true)
    assert_equal 4, answer_form.answers.length
    answer_form.answers.each { |a| assert_equal "foo", a.answer_text }
  end
end
