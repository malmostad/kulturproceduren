# -*- encoding : utf-8 -*-
require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)

    @user = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "index" do
    questions = create_list(:question, 2, :template => true).sort_by(&:question)

    create_list(:question, 2, :template => false).sort_by(&:question) # dummies

    get :index
    assert_response :success
    assert_equal    questions, assigns(:questions)
    assert          assigns(:question).new_record?
    assert          assigns(:question).template
    assert          assigns(:question).mandatory
    assert_equal    "QuestionMark", assigns(:question).qtype
  end

  test "edit, template" do
    questions = create_list(:question, 3, :template => true).sort_by(&:question)
    question  = questions.second

    create_list(:question, 2, :template => false).sort_by(&:question) # dummies

    get :edit, :id => question.id
    assert_response :success
    assert_template "questions/index"
    assert_equal    question,  assigns(:question)
    assert_equal    questions, assigns(:questions)
  end
  test "edit, not template" do
    question      = create(:question, :template => false)
    questionnaire = create(:questionnaire)
    templates     = create_list(:question, 3, :template => true).sort_by(&:question)

    get :edit, :id => question.id, :questionnaire_id => questionnaire.id
    assert_response :success
    assert_equal    question,      assigns(:question)
    assert_equal    questionnaire, assigns(:questionnaire)
    assert_equal    templates,     assigns(:template_questions)
  end

  test "create, without questionnaire" do
    questions = create_list(:question, 3, :template => true).sort_by(&:question)
    create_list(:question, 3, :template => false) # dummies

    # Invalid
    post :create, :question => { :question => nil }
    assert_response :success
    assert_template "questions/index"
    assert_equal    questions, assigns(:questions)
    assert          !assigns(:question).valid?

    # Valid
    post :create, :question => { :question => "Foo" }
    assert_redirected_to :action => "index"
    assert_equal         "Frågan skapades.", flash[:notice]
    assert_equal         "Foo",              Question.last.question
  end
  test "create, with questionnaire" do
    questionnaire = create(:questionnaire)
    questions = create_list(:question, 3, :template => true).sort_by(&:question)
    create_list(:question, 3, :template => false) # dummies

    # Invalid
    post :create, :questionnaire_id => questionnaire.id, :question => { :question => nil }
    assert_response :success
    assert_template "questionnaires/show"
    assert_equal    questionnaire, assigns(:questionnaire)
    assert_equal    questions,     assigns(:template_questions)
    assert          !assigns(:question).valid?

    # Valid
    post :create, :questionnaire_id => questionnaire.id, :question => { :question => "Foo" }
    assert_redirected_to questionnaire
    assert_equal         "Frågan skapades.", flash[:notice]

    question = Question.last
    assert_equal "Foo", question.question
    assert       questionnaire.questions(true).include?(question)
  end

  test "update, without questionnaire" do
    questions = create_list(:question, 3, :template => true, :question => "Bar").sort_by(&:question)
    question  = questions.second
    create_list(:question, 3, :template => false) # dummies

    # Invalid
    put :update, :id => question.id, :question => { :question => nil }
    assert_response :success
    assert_template "questions/index"
    assert_equal    questions, assigns(:questions)
    assert_equal    question, assigns(:question)
    assert          !assigns(:question).valid?

    # Valid
    put :update, :id => question.id, :question => { :question => "Foo" }
    assert_redirected_to :action => "index"
    assert_equal         "Frågan uppdaterades.", flash[:notice]
    assert_equal         "Foo",                  question.reload.question
  end
  test "update, with questionnaire" do
    questionnaire = create(:questionnaire)
    questions     = create_list(:question, 3, :template => true).sort_by(&:question)
    question      = questions.second
    create_list(:question, 3, :template => false) # dummies

    # Invalid
    put :update, :id => question.id, :questionnaire_id => questionnaire.id, :question => { :question => nil }
    assert_response :success
    assert_template "questions/edit"
    assert_equal    questionnaire, assigns(:questionnaire)
    assert_equal    questions,     assigns(:template_questions)
    assert          !assigns(:question).valid?

    # Valid
    put :update, :id => question.id, :questionnaire_id => questionnaire.id, :question => { :question => "Foo" }
    assert_redirected_to questionnaire
    assert_equal         "Frågan uppdaterades.", flash[:notice]
    assert_equal         "Foo",                  question.reload.question
  end

  test "destroy" do
    question = create(:question)
    
    delete :destroy, :id => question.id
    assert_redirected_to :action => "index"
    assert_equal         "Frågan togs bort", flash[:notice]

    question = create(:question)
    questionnaire = create(:questionnaire)

    delete :destroy, :id => question.id, :questionnaire_id => questionnaire.id
    assert_redirected_to questionnaire
    assert_equal         "Frågan togs bort", flash[:notice]
  end
end
