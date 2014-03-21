# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class QuestionnairesControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)

    @user = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "index" do
    questionnaires = create_list(:questionnaire, 3).sort_by { |q| q.event.name }
    Questionnaire.find_unbooking

    get :index
    assert_response :success
    assert_equal questionnaires, assigns(:questionnaires)
  end

  test "show, for event" do
    questions = create_list(:question, 2, :template => false)
    templates = create_list(:question, 2, :template => true).sort_by(&:question)
    questionnaire = create(:questionnaire)

    get :show, :id => questionnaire.id

    assert_response :success
    assert_equal    questionnaire, assigns(:questionnaire)
    assert          assigns(:question).new_record?
    assert          !assigns(:question).template
    assert_equal    "QuestionMark", assigns(:question).qtype
    assert_equal    templates,      assigns(:template_questions)
  end
  test "show, for unbooking" do
    questionnaire = Questionnaire.find_unbooking

    get :show, :id => questionnaire.id

    assert_response :success
    assert_equal    questionnaire, assigns(:questionnaire)
    assert          assigns(:question).new_record?
    assert          !assigns(:question).template
    assert_equal    "QuestionMark", assigns(:question).qtype
    assert_nil      assigns(:template_questions)
  end

  test "unbooking" do
    get :unbooking
    assert_redirected_to Questionnaire.find_unbooking
  end

  test "add template question" do
    question = create(:question)
    questionnaire = create(:questionnaire)

    assert !questionnaire.questions.include?(question)

    post :add_template_question, :id => questionnaire.id, :question_id => question.id
    assert_redirected_to questionnaire
    assert               questionnaire.questions(true).include?(question)
  end

  test "remove template question" do
    question = create(:question)
    questionnaire = create(:questionnaire)

    questionnaire.questions << question

    post :remove_template_question, :id => questionnaire.id, :question_id => question.id
    assert_redirected_to questionnaire
    assert               !questionnaire.questions(true).include?(question)
  end

  test "new" do
    event = create(:event)
    questionnaire = create(:questionnaire) # With event

    get :new
    assert_response :success
    assert_equal    [event], assigns(:events)
    assert          assigns(:questionnaire).new_record?
  end

  test "edit" do
    questionnaire = create(:questionnaire)
    
    get :edit, :id => questionnaire.id
    assert_response :success
    assert_template "questionnaires/new"
    assert_equal    questionnaire, assigns(:questionnaire)
  end

  test "create, valid" do
    event     = create(:event)
    questions = create_list(:question, 2, :template => false)
    templates = create_list(:question, 2, :template => true).sort_by(&:question)

    post :create, :questionnaire => { :event_id => event.id }
    assert_equal "Enkäten skapades.", flash[:notice]

    questionnaire = Questionnaire.last
    assert_redirected_to questionnaire
    assert               questionnaire.for_event?
    assert_equal         templates, questionnaire.questions
  end
  test "create, invalid" do
    event = create(:event)
    questionnaire = create(:questionnaire) # With event

    Questionnaire.any_instance.stubs(:valid?).returns(false)

    post :create, :questionnaire => {}
    assert_response :success
    assert_template "questionnaires/new"
    assert_equal    [event], assigns(:events)
  end

  test "update, valid" do
    questionnaire = create(:questionnaire, :description => "Bar")

    put :update, :id => questionnaire.id, :questionnaire => { :description => "Foo" }
    assert_redirected_to questionnaire
    assert_equal         "Enkäten uppdaterades.", flash[:notice]
    assert_equal         "Foo", questionnaire.reload.description
  end
  test "update, invalid" do
    event = create(:event)
    questionnaire = create(:questionnaire) # With event

    Questionnaire.any_instance.stubs(:valid?).returns(false)

    put :update, :id => questionnaire.id, :questionnaire => {}
    assert_response :success
    assert_template "questionnaires/new"
    assert_equal    [event], assigns(:events)
  end

  test "destroy" do
    questionnaire = create(:questionnaire)

    delete :destroy, :id => questionnaire.id
    assert_redirected_to questionnaires_url()
    assert_nil           Questionnaire.where(:id => questionnaire.id).first
  end
end
