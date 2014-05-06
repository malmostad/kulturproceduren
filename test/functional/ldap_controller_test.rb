# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class LdapControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)
  end

  test "index" do
    get :index
    assert_response :success
  end

  test "search, normal result" do
    APP_CONFIG.replace(ldap: { max_search_results: 10 })

    result_mock = stub(:empty? => false,      length: 9, each: nil)
    ldap_mock   = stub(:max_results= => true, search: result_mock)
    @controller.stubs(:get_ldap).returns(ldap_mock)

    get :search, ldapquery: {}
    assert_response :success
    assert_equal    result_mock, assigns(:result)
    assert_nil      flash[:warning]
  end
  test "search, too many hits" do
    APP_CONFIG.replace(ldap: { max_search_results: 10 })

    result_mock = stub(:empty? => false,      length: 11, each: nil, delete_at: nil)
    ldap_mock   = stub(:max_results= => true, search: result_mock)
    @controller.stubs(:get_ldap).returns(ldap_mock)

    get :search, ldapquery: {}
    assert_response :success
    assert_equal    result_mock, assigns(:result)
    assert_equal    "Sökningen resulterade i för många träffar. Var god begränsa sökningen nedan.", flash[:warning]
  end
  test "search, no result" do
    APP_CONFIG.replace(ldap: { max_search_results: 10 })

    result_mock = stub(:empty? => true,      length: 0, each: nil)
    ldap_mock   = stub(:max_results= => true, search: result_mock)
    @controller.stubs(:get_ldap).returns(ldap_mock)

    get :search, ldapquery: {}
    assert_response :success
    assert_equal    result_mock, assigns(:result)
    assert_equal    "Inga träffar hittades.", flash[:warning]
  end

  test "handle" do
    APP_CONFIG.replace(salt_length: 4, ldap: { username_prefix: "ldap" })

    user = create(:user, username: "zomg")

    # User found
    get :handle, username: "zomg"
    assert_redirected_to user
    assert_equal user.updated_at, User.find(user.id).updated_at

    # User not found
    ldap_user_mock = { name: "Name", email: "name@example.com", cellphone: "123", username: "zomglol" }
    ldap_mock      = stub(get_user: ldap_user_mock)
    @controller.stubs(:get_ldap).returns(ldap_mock)

    get :handle, username: "zomg1"

    user = User.last
    assert_redirected_to user
    assert_equal         "Name",             user.name
    assert_equal         "name@example.com", user.email
    assert_equal         "ldapzomglol",      user.username
    assert_equal         "123",              user.cellphone
    assert               user.authenticate("ldap")
  end
end
