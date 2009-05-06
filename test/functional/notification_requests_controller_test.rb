require 'test_helper'

class NotificationRequestsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:notification_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create notification_request" do
    assert_difference('NotificationRequest.count') do
      post :create, :notification_request => { }
    end

    assert_redirected_to notification_request_path(assigns(:notification_request))
  end

  test "should show notification_request" do
    get :show, :id => notification_requests(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => notification_requests(:one).to_param
    assert_response :success
  end

  test "should update notification_request" do
    put :update, :id => notification_requests(:one).to_param, :notification_request => { }
    assert_redirected_to notification_request_path(assigns(:notification_request))
  end

  test "should destroy notification_request" do
    assert_difference('NotificationRequest.count', -1) do
      delete :destroy, :id => notification_requests(:one).to_param
    end

    assert_redirected_to notification_requests_path
  end
end
