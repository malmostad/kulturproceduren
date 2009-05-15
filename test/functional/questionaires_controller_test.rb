require 'test_helper'

class QuestionairesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:questionaires)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create questionaire" do
    assert_difference('Questionaire.count') do
      post :create, :questionaire => { }
    end

    assert_redirected_to questionaire_path(assigns(:questionaire))
  end

  test "should show questionaire" do
    get :show, :id => questionaires(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => questionaires(:one).to_param
    assert_response :success
  end

  test "should update questionaire" do
    put :update, :id => questionaires(:one).to_param, :questionaire => { }
    assert_redirected_to questionaire_path(assigns(:questionaire))
  end

  test "should destroy questionaire" do
    assert_difference('Questionaire.count', -1) do
      delete :destroy, :id => questionaires(:one).to_param
    end

    assert_redirected_to questionaires_path
  end
end
