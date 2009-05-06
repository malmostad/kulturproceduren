require 'test_helper'

class BookingRequirementsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:booking_requirements)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create booking_requirement" do
    assert_difference('BookingRequirement.count') do
      post :create, :booking_requirement => { }
    end

    assert_redirected_to booking_requirement_path(assigns(:booking_requirement))
  end

  test "should show booking_requirement" do
    get :show, :id => booking_requirements(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => booking_requirements(:one).to_param
    assert_response :success
  end

  test "should update booking_requirement" do
    put :update, :id => booking_requirements(:one).to_param, :booking_requirement => { }
    assert_redirected_to booking_requirement_path(assigns(:booking_requirement))
  end

  test "should destroy booking_requirement" do
    assert_difference('BookingRequirement.count', -1) do
      delete :destroy, :id => booking_requirements(:one).to_param
    end

    assert_redirected_to booking_requirements_path
  end
end
