require_relative '../test_helper'

class SchoolsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)
  end

  test "index" do
    schools = create_list(:school, 3).sort_by(&:name)
    get :index
    assert_response :success
    assert_equal    schools, assigns(:schools)
  end

  test "show" do
    school = create(:school_with_groups)
    get :show, id: school.id
    assert_response :success
    assert_equal    school,             assigns(:school)
    assert_equal    school.groups.to_a, assigns(:groups)
  end

  test "history" do
    school = create(:school)
    get :history, id: school.id
    assert_response :success
    assert_equal    school, assigns(:school)
  end

  test "new" do
    districts = create_list(:district, 3)

    get :new
    assert_response :success
    assert          assigns(:school).new_record?
    assert_nil      assigns(:school).district
    assert_equal    districts, assigns(:districts)

    get :new, district_id: districts.second.id
    assert_response :success
    assert          assigns(:school).new_record?
    assert_equal    districts.second, assigns(:school).district
    assert_equal    districts,        assigns(:districts)
  end


  test "create" do
    districts = create_list(:district, 3)

    # Invalid
    post :create, school: {}
    assert_response :success
    assert          assigns(:school).new_record?
    assert_equal    districts, assigns(:districts)

    # Valid
    post :create, school: { name: "School", district_id: districts.second.id }

    school = School.last
    assert_redirected_to school
    assert_equal    "Skolan skapades.", flash[:notice]
    assert_equal    districts.second,   school.district
    assert_equal    "School",           school.name
  end

  test "update" do
    districts = create_list(:district, 3)
    school    = create(:school, district: districts.second, name: "Update me")

    # Invalid
    put :update, id: school.id, school: { name: "" }
    assert_response :success
    assert_equal    school,    assigns(:school)
    assert          !assigns(:school).valid?
    assert_equal    districts, assigns(:districts)

    # Valid
    put :update, id: school.id, school: { name: "Updated" }
    assert_redirected_to school
    assert_equal         "Skolan uppdaterades.", flash[:notice]
    assert_equal         "Updated",              school.reload.name
  end

  test "destroy" do
    school = create(:school)
    delete :destroy, id: school.id
    assert_redirected_to school.district
    assert_equal         "Skolan togs bort.", flash[:notice]
    assert_nil           School.where(id: school.id).first
  end

  test "search" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    school1 = create(:school, name: "foo")
    school2 = create(:school, name: "ofoo")
    school3 = create(:school, name: "bar")

    # Search by prefix, by default
    post :search, term: "fo"
    assert_response :success
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    %w(foo).to_json, @response.body

    # Expand to wildcard when there is no prefix match
    post :search, term: "ar"
    assert_response :success
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    %w(bar).to_json, @response.body
  end

  test "select" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    session[:group_selection] = nil

    school = create(:school)

    get :select, school_id: school.id, return_to: "/foo/bar"
    assert_redirected_to "/foo/bar"
    assert_equal({
      school_id: school.id,
      school_name: school.name,
      district_id: school.district.id
    }, session[:group_selection])

    school = create(:school)

    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :select, school_id: school.id, return_to: "/foo/bar"
    assert_response :success
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal({
      school_id: school.id,
      school_name: school.name,
      district_id: school.district.id
    }, session[:group_selection])
  end
  test "select, no school" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    session[:group_selection] = nil

    get :select, school_id: -1, return_to: "/foo/bar"
    assert_redirected_to "/foo/bar"
    assert_nil           session[:group_selection]

    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :select, school_id: -1, return_to: "/foo/bar"
    assert_response :success
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_nil      session[:group_selection]
  end

  test "options list, errors" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    get :options_list, district_id: -1, occasion_id: -1
    assert_response 404
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/

    error_stub = stub do
      stubs(:to_i).raises
    end
    get :options_list, district_id: error_stub
    assert_response 404
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
  end
  test "options list, without district without occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    schools = create_list(:school, 3).sort_by(&:name)

    get :options_list
    assert_response :success
    assert_template "schools/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    schools, assigns(:schools)
  end
  test "options list, with district without occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    schools                   = create_list(:school, 3).sort_by(&:name)
    session[:group_selection] = nil

    get :options_list, district_id: schools.second.district.id
    assert_response :success
    assert_template "schools/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    [schools.second], assigns(:schools)
    assert_equal(   { district_id: schools.second.district.id }, session[:group_selection])
  end
  test "options list, without district with occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    occasion = create(:occasion)
    schools  = create_list(:school_with_groups, 3).sort_by(&:name)

    create(:ticket, occasion: occasion, event: occasion.event, group: schools.second.groups.second)

    get :options_list, occasion_id: occasion.id
    assert_response :success
    assert_template "schools/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    [schools.second], assigns(:schools)
  end
  test "options list, with district with occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    occasion = create(:occasion)
    schools  = create_list(:school_with_groups, 3).sort_by(&:name)

    create(:ticket, occasion: occasion, event: occasion.event, group: schools.first.groups.second)
    create(:ticket, occasion: occasion, event: occasion.event, group: schools.second.groups.second)

    get :options_list, occasion_id: occasion.id, district_id: schools.second.district.id
    assert_response :success
    assert_template "schools/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    [schools.second], assigns(:schools)
  end
end
