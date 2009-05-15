require 'test_helper'

class CultureProvidersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:culture_providers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create culture_provider" do
    assert_difference('CultureProvider.count') do
      post :create, :culture_provider => { }
    end

    assert_redirected_to culture_provider_path(assigns(:culture_provider))
  end

  test "should show culture_provider" do
    get :show, :id => culture_providers(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => culture_providers(:one).to_param
    assert_response :success
  end

  test "should update culture_provider" do
    put :update, :id => culture_providers(:one).to_param, :culture_provider => { }
    assert_redirected_to culture_provider_path(assigns(:culture_provider))
  end

  test "should destroy culture_provider" do
    assert_difference('CultureProvider.count', -1) do
      delete :destroy, :id => culture_providers(:one).to_param
    end

    assert_redirected_to culture_providers_path
  end
end
