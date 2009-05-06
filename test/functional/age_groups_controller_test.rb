require 'test_helper'

class AgeGroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:age_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create age_group" do
    assert_difference('AgeGroup.count') do
      post :create, :age_group => { }
    end

    assert_redirected_to age_group_path(assigns(:age_group))
  end

  test "should show age_group" do
    get :show, :id => age_groups(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => age_groups(:one).to_param
    assert_response :success
  end

  test "should update age_group" do
    put :update, :id => age_groups(:one).to_param, :age_group => { }
    assert_redirected_to age_group_path(assigns(:age_group))
  end

  test "should destroy age_group" do
    assert_difference('AgeGroup.count', -1) do
      delete :destroy, :id => age_groups(:one).to_param
    end

    assert_redirected_to age_groups_path
  end
end
