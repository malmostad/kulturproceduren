# Tests ApplicationController
require 'test_helper'

class ApplicationProxyController < ApplicationController
  def test_load_group_selection_collections
    occasion = params[:occasion_id] ? Occasion.find(params[:occasion_id]) : nil
    load_group_selection_collections(occasion)
    render nothing: true
  end
  def test_sort_order
    render text: sort_order(params[:default])
  end
  def test_authenticate
    result = authenticate
    render(nothing: true) if result != false
  end
  def test_require_admin
    @current_user = nil
    result = require_admin
    render(nothing: true) if result != false
  end
  def test_user_online
    @result = user_online?
    render nothing: true
  end
  def test_current_user
    @result = current_user
    render nothing: true
  end
  def test_occasion_list_cache_key
    event = Event.find(params[:event_id])
    @current_user = nil
    @result = occasion_list_cache_key(event)
    render nothing: true
  end
  def test_send_csv
    send_csv(params[:filename], params[:csv])
  end
end

class ApplicationProxyControllerTest < ActionController::TestCase
  test "load group selection collections" do
    districts = create_list(:district_with_groups, 2)

    assert_nil session[:group_selection]

    # no selection, no occasion
    get :test_load_group_selection_collections
    assert_equal({},        session[:group_selection])
    assert_equal districts, assigns(:group_selection_collections)[:districts]
    assert_nil   assigns(:group_selection_collections)[:schools]
    assert_nil   assigns(:group_selection_collections)[:groups]

    # district, no occasion
    district = districts.first
    session[:group_selection][:district_id] = district.id
    get :test_load_group_selection_collections
    assert_equal districts,                        assigns(:group_selection_collections)[:districts]
    assert_equal district.schools.sort_by(&:name), assigns(:group_selection_collections)[:schools]
    assert_nil   assigns(:group_selection_collections)[:groups]

    # school, no occasion
    school = district.schools.second
    session[:group_selection][:school_id] = school.id
    get :test_load_group_selection_collections
    assert_equal districts,                        assigns(:group_selection_collections)[:districts]
    assert_equal district.schools.sort_by(&:name), assigns(:group_selection_collections)[:schools]
    assert_equal school.groups.sort_by(&:name),    assigns(:group_selection_collections)[:groups]

    # occasion setup
    group = school.groups.second
    occasion = create(:occasion)
    occasion.event.ticket_state = :alloted_group
    create(:ticket, event: occasion.event, group: group, district: district, state: :unbooked)

    # no selection, occasion
    session[:group_selection] = nil
    get :test_load_group_selection_collections, occasion_id: occasion.id
    assert_equal({},         session[:group_selection])
    assert_equal [district], assigns(:group_selection_collections)[:districts]
    assert_nil   assigns(:group_selection_collections)[:schools]
    assert_nil   assigns(:group_selection_collections)[:groups]

    # district, occasion
    session[:group_selection][:district_id] = district.id
    get :test_load_group_selection_collections, occasion_id: occasion.id
    assert_equal [district], assigns(:group_selection_collections)[:districts]
    assert_equal [school],   assigns(:group_selection_collections)[:schools]
    assert_nil   assigns(:group_selection_collections)[:groups]

    # school, occasion
    session[:group_selection][:school_id] = school.id
    get :test_load_group_selection_collections, occasion_id: occasion.id
    assert_equal [district], assigns(:group_selection_collections)[:districts]
    assert_equal [school],   assigns(:group_selection_collections)[:schools]
    assert_equal [group],    assigns(:group_selection_collections)[:groups]
  end
  test "sort order" do
    get :test_sort_order, default: "foo"
    assert_equal "foo ASC", @response.body
    get :test_sort_order, default: "foo", c: "bar"
    assert_equal "bar ASC", @response.body
    get :test_sort_order, default: "foo", c: "bar", d: "down"
    assert_equal "bar DESC", @response.body
  end
  test "authenticate" do
    session[:current_user_id] = nil
    get :test_authenticate, foo: 1
    assert_redirected_to controller: "login"
    assert_equal "Du har inte behörighet att komma åt sidan. Var god logga in.", flash[:error]
    assert_equal({"controller" => "application_proxy", "action" => "test_authenticate", "foo" => "1"}, session[:return_to])

    session[:current_user_id] = 1
    get :test_authenticate
    assert_response :success
  end
  test "require admin" do
    session[:current_user_id] = create(:user, roles: [roles(:booker)]).id
    get :test_require_admin
    assert_redirected_to action: "index"
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:notice]

    session[:current_user_id] = create(:user, roles: [roles(:admin)]).id
    get :test_require_admin
    assert_response :success
  end
  test "user online?" do
    session[:current_user_id] = nil
    get :test_user_online
    assert !assigns(:result)
    session[:current_user_id] = 1
    get :test_user_online
    assert assigns(:result)
  end
  test "current user" do
    user = create(:user)
    get :test_current_user
    assert_nil assigns(:result)
    session[:current_user_id] = user.id
    get :test_current_user
    assert_equal user, assigns(:result)
  end
  test "occasion list cache key" do
    event = create(:event)

    # No current user
    get :test_occasion_list_cache_key, event_id: event.id
    assert_equal "events/show/#{event.id}/occasion_list/not_online/not_bookable/not_administratable/not_reportable", assigns(:result)

    # Regular user online
    session[:current_user_id] = create(:user).id
    get :test_occasion_list_cache_key, event_id: event.id
    assert_equal "events/show/#{event.id}/occasion_list/online/not_bookable/not_administratable/not_reportable", assigns(:result)

    # Booker online
    session[:current_user_id] = create(:user, roles: [roles(:booker)]).id
    get :test_occasion_list_cache_key, event_id: event.id
    assert_equal "events/show/#{event.id}/occasion_list/online/bookable/not_administratable/not_reportable", assigns(:result)

    # Culture provider online
    session[:current_user_id] = create(:user, roles: [roles(:culture_worker)], culture_providers: [event.culture_provider]).id
    get :test_occasion_list_cache_key, event_id: event.id
    assert_equal "events/show/#{event.id}/occasion_list/online/not_bookable/administratable/not_reportable", assigns(:result)

    # Host online
    session[:current_user_id] = create(:user, roles: [roles(:host)]).id
    get :test_occasion_list_cache_key, event_id: event.id
    assert_equal "events/show/#{event.id}/occasion_list/online/not_bookable/not_administratable/reportable", assigns(:result)

    # Admin online
    session[:current_user_id] = create(:user, roles: [roles(:admin)]).id
    get :test_occasion_list_cache_key, event_id: event.id
    assert_equal "events/show/#{event.id}/occasion_list/online/bookable/administratable/reportable", assigns(:result)
  end
  test "send csv" do
    filename = "test.tsv"
    data = "ÅÄÖ\tåäö\nABC\tabc"

    get :test_send_csv, filename: filename, csv: data
    assert_equal data.gsub(/\n/, "\r\n").encode("windows-1252"), @response.body
    assert_equal "inline; filename=\"test.tsv\"", @response.headers["Content-Disposition"]
    assert_equal "text/csv; charset=windows-1252; header=present", @response.headers["Content-Type"]
  end
end
