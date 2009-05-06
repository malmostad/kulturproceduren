require 'test_helper'

class CultureAdministratorsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:culture_administrators)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create culture_administrator" do
    assert_difference('CultureAdministrator.count') do
      post :create, :culture_administrator => { }
    end

    assert_redirected_to culture_administrator_path(assigns(:culture_administrator))
  end

  test "should show culture_administrator" do
    get :show, :id => culture_administrators(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => culture_administrators(:one).to_param
    assert_response :success
  end

  test "should update culture_administrator" do
    put :update, :id => culture_administrators(:one).to_param, :culture_administrator => { }
    assert_redirected_to culture_administrator_path(assigns(:culture_administrator))
  end

  test "should destroy culture_administrator" do
    assert_difference('CultureAdministrator.count', -1) do
      delete :destroy, :id => culture_administrators(:one).to_param
    end

    assert_redirected_to culture_administrators_path
  end
end
