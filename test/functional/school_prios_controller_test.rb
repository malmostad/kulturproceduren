require 'test_helper'

class SchoolPriosControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:school_prios)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create school_prio" do
    assert_difference('SchoolPrio.count') do
      post :create, :school_prio => { }
    end

    assert_redirected_to school_prio_path(assigns(:school_prio))
  end

  test "should show school_prio" do
    get :show, :id => school_prios(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => school_prios(:one).to_param
    assert_response :success
  end

  test "should update school_prio" do
    put :update, :id => school_prios(:one).to_param, :school_prio => { }
    assert_redirected_to school_prio_path(assigns(:school_prio))
  end

  test "should destroy school_prio" do
    assert_difference('SchoolPrio.count', -1) do
      delete :destroy, :id => school_prios(:one).to_param
    end

    assert_redirected_to school_prios_path
  end
end
