require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)

    @user = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "index" do
    groups = create_list(:group, 3).sort_by(&:name)
    get :index
    assert_response :success
    assert_equal    groups, assigns(:groups)
  end

  test "show" do
    group = create(:group)
    get :show, :id => group.id
    assert_response :success
    assert_equal    group, assigns(:group)
    assert          assigns(:age_group).new_record?
    assert_equal    group, assigns(:age_group).group
  end

  test "new" do
    schools = create_list(:school, 3).sort_by(&:name)

    get :new
    assert_response :success
    assert          assigns(:group).new_record?
    assert_nil      assigns(:group).school_id
    assert_equal    schools, assigns(:schools)

    get :new, :school_id => schools.last.id
    assert_response :success
    assert          assigns(:group).new_record?
    assert_equal    schools.last, assigns(:group).school
    assert_equal    schools,      assigns(:schools)
  end

  test "edit" do
    schools = create_list(:school, 3).sort_by(&:name)
    group   = create(:group, :school => schools.last)

    get :edit, :id => group.id
    assert_response :success
    assert_template "groups/new"
    assert_equal    group, assigns(:group)
    assert_equal    schools, assigns(:schools)
  end

  test "create" do
    schools = create_list(:school, 3).sort_by(&:name)

    # Invalid
    post :create, :group => { :name => "" }
    assert_response :success
    assert_template "groups/new"
    assert          !assigns(:group).valid?
    assert_equal    schools, assigns(:schools)

    # Valid
    post :create, :group => { :name => "zomg", :school_id => schools.last.id }

    group = Group.last
    assert_redirected_to group
    assert_equal         "Gruppen skapades.", flash[:notice]
    assert_equal         "zomg", group.name
  end

  test "update" do
    schools = create_list(:school, 3).sort_by(&:name)
    group = create(:group, :school => schools.last, :name => "foo")

    # Invalid
    put :update, :id => group.id, :group => { :name => "" }
    assert_response :success
    assert_template "groups/new"
    assert_equal    group, assigns(:group)
    assert          !assigns(:group).valid?
    assert_equal    schools, assigns(:schools)

    # Valid
    put :update, :id => group.id, :group => { :name => "zomg" }

    group.reload
    assert_redirected_to group
    assert_equal         "Gruppen uppdaterades.", flash[:notice]
    assert_equal         "zomg", group.name
  end

  test "move first in priority" do
    group1 = create(:group, :priority => 1)
    group2 = create(:group, :priority => 2)
    group3 = create(:group, :priority => 3)

    # No redirect
    get :move_first_in_priority, :id => group3.id
    assert_redirected_to group_url()
    assert_equal 1, group3.reload.priority
    assert_equal 2, group1.reload.priority
    assert_equal 3, group2.reload.priority

    # Redirect
    get :move_first_in_priority, :id => group1.id, :return_to => "/foo/bar"
    assert_redirected_to "/foo/bar"
    assert_equal 1, group1.reload.priority
    assert_equal 2, group3.reload.priority
    assert_equal 3, group2.reload.priority
  end

  test "move last in priority" do
    group1 = create(:group, :priority => 1)
    group2 = create(:group, :priority => 2)
    group3 = create(:group, :priority => 3)

    # No redirect
    get :move_last_in_priority, :id => group1.id
    assert_redirected_to group_url()
    assert_equal 1, group2.reload.priority
    assert_equal 2, group3.reload.priority
    assert_equal 3, group1.reload.priority

    # Redirect
    get :move_last_in_priority, :id => group3.id, :return_to => "/foo/bar"
    assert_redirected_to "/foo/bar"
    assert_equal 1, group2.reload.priority
    assert_equal 2, group1.reload.priority
    assert_equal 3, group3.reload.priority
  end

  test "destroy" do
    group = create(:group)
    delete :destroy, :id => group.id
    assert_redirected_to group.school
    assert_equal         "Gruppen togs bort.", flash[:notice]
    assert_nil           Group.first(:conditions => { :id => group.id })
  end

  test "select" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    group                     = create(:group)
    session[:group_selection] = nil

    get :select, :group_id => group.id, :return_to => "/foo/bar"
    assert_redirected_to "/foo/bar"
    assert_equal({
      :group_id => group.id,
      :school_id => group.school.id,
      :district_id => group.school.district.id
    }, session[:group_selection])

    # XHR and error
    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"

    get :select, :group_id => -1, :return_to => "/foo/bar"
    assert_response :success
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal({
      :group_id => group.id,
      :school_id => group.school.id,
      :district_id => group.school.district.id
    }, session[:group_selection])
  end

  test "options list, errors" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    # 404 by school_id == -1
    get :options_list, :school_id => "-1"
    assert_response 404
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    
    # 404 by occasion_id == -1
    get :options_list, :occasion_id => "-1"
    assert_response 404
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/

    # 404 by error (school not found)
    get :options_list, :school_id => 1
    assert_response 404
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
  end
  test "options list, without school and occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    groups = create_list(:group, 3).sort_by(&:name)

    get :options_list
    assert_response :success
    assert_template "groups/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    groups, assigns(:groups)
  end
  test "options list, with school and without occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    groups                    = create_list(:group, 3).sort_by(&:name)
    session[:group_selection] = nil

    get :options_list, :school_id => groups.first.school.id
    assert_response :success
    assert_template "groups/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    [groups.first], assigns(:groups)
    assert_equal({
      :school_id   => groups.first.school.id,
      :district_id => groups.first.school.district.id
    }, session[:group_selection])
  end
  test "options list, without school and with occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    occasion = create(:occasion)
    groups   = create_list(:group, 3).sort_by(&:name)

    create(:ticket, :occasion => occasion, :event => occasion.event, :group => groups.second)

    get :options_list, :occasion_id => occasion.id
    assert_response :success
    assert_template "groups/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    occasion,        assigns(:occasion)
    assert_equal    [groups.second], assigns(:groups)
  end
  test "options list, with school and with occasion" do
    @controller.unstub(:authenticate)
    @controller.unstub(:require_admin)

    occasion = create(:occasion)
    school   = create(:school)
    group1   = create(:group, :school => school) # match by both school and ticket below
    group2   = create(:group) # only match by ticket
    create(:group, :school => school) # only match by school

    create(:ticket, :occasion => occasion, :event => occasion.event, :group => group1)
    create(:ticket, :occasion => occasion, :event => occasion.event, :group => group2)

    get :options_list, :occasion_id => occasion.id, :school_id => school.id
    assert_response :success
    assert_template "groups/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    occasion, assigns(:occasion)
    assert_equal    [group1], assigns(:groups)
  end
end
