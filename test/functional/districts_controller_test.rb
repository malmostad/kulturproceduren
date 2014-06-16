require 'test_helper'

class DistrictsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)

    @user = create(:user, roles: [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "index" do
    districts = create_list(:district, 3)
    get :index
    assert_response :success
    assert_equal    [@user.districts + districts].flatten.sort_by(&:name), assigns(:districts)
  end

  test "show" do
    district = create(:district)
    get :show, id: district.id
    assert_response :success
    assert_equal    district, assigns(:district)
  end

  test "new" do
    get :new
    assert_response :success
    assert          assigns(:district).new_record?
  end

  test "edit" do
    district = create(:district)
    get :edit, id: district.id
    assert_response :success
    assert_template "districts/new"
    assert_equal    district, assigns(:district)
  end

  test "create" do
    # Invalid
    post :create, district: { name: "" }
    assert_response :success
    assert_template "districts/new"
    assert          assigns(:district).new_record?
    assert          !assigns(:district).valid?

    # Valid
    school_type = create(:school_type)
    post :create, district: { name: "zomg", school_type_id: school_type.id }
    assert_redirected_to assigns(:district)
    assert_equal         "Området skapades.", flash[:notice]
    assert_equal         "zomg", District.find(assigns(:district).id).name
  end

  test "update" do
    district = create(:district, name: "foo")

    # Invalid
    put :update, id: district.id, district: { name: "" }
    assert_response :success
    assert_template "districts/new"
    assert_equal    district, assigns(:district)
    assert          !assigns(:district).valid?

    # Invalid
    put :update, id: district.id, district: { name: "zomg" }
    assert_redirected_to district
    assert_equal         "Området uppdaterades.", flash[:notice]

    district.reload
    assert_equal "zomg", district.name
  end

  test "destroy" do
    district = create(:district)
    delete :destroy, id: district.id
    assert_redirected_to districts_url()
    assert_equal         "Området togs bort.", flash[:notice]
    assert_nil           District.where(id: district.id).first
  end

  test "select" do
    @controller.unstub(:require_admin)

    session[:group_selection] = nil
    district1                 = create(:district)
    district2                 = create(:district)

    # Normal
    get :select, district_id: district1.id, return_to: "/foo"
    assert_redirected_to "/foo"
    assert_equal(        { district_id: district1.id }, session[:group_selection])

    # XHR
    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :select, district_id: district2.id, return_to: "/foo"
    assert_response :success
    assert_equal(   { district_id: district2.id }, session[:group_selection])
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
  end
  test "select, no district" do
    @controller.unstub(:require_admin)

    session[:group_selection] = nil

    # Normal
    get :select, district_id: nil, return_to: "/foo"
    assert_redirected_to "/foo"
    assert_nil           session[:group_selection]

    # XHR
    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :select, district_id: nil, return_to: "/foo"
    assert_response :success
    assert_nil      session[:group_selection]
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
  end
end
