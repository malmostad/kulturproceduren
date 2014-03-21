# -*- encoding : utf-8 -*-
require 'test_helper'

class CalendarControllerTest < ActionController::TestCase

  test "set list" do
    [:index, :filter, :apply_filter, :clear_filter].each do |action|
      get action
      assert_equal :occasions, assigns(:calendar_list)

      get action, :list => "foo"
      assert_equal :occasions, assigns(:calendar_list)

      get action, :list => "events"
      assert_equal :events, assigns(:calendar_list)
    end
  end

  test "index" do
    create_list(:category_group, 2)
    create_list(:event, 2)
    create_list(:event_with_occasions, 2)

    # Occasions
    get :index
    assert_response :success
    assert          !assigns(:category_groups).blank?
    assert_equal    CategoryGroup.order("name ASC").to_a,            assigns(:category_groups)
    assert          !assigns(:occasions).blank?
    assert_equal    Occasion.search({ :from_date => Date.today }, nil), assigns(:occasions)

    # Events
    get :index, :list => "events"
    assert_response :success
    assert          !assigns(:category_groups).blank?
    assert_equal    CategoryGroup.order("name ASC").to_a,                  assigns(:category_groups)
    assert          !assigns(:events).blank?
    assert_equal    Event.search_standing({ :from_date => Date.today }, nil), assigns(:events)
  end
  test "index with cache" do
    @controller.expects(:fragment_exist?).twice.returns(true)

    get :index
    assert_response :success
    assert_nil assigns(:category_groups)
    assert_nil assigns(:occasions)
    assert_nil assigns(:events)

    get :index, :list => "events"
    assert_response :success
    assert_nil assigns(:category_groups)
    assert_nil assigns(:occasions)
    assert_nil assigns(:events)
  end

  test "filter" do
    create_list(:category_group, 2)
    create_list(:event, 2)
    create_list(:event_with_occasions, 2)

    session[:calendar_filter] = { :from_date => Date.today - 1 }

    # Occasions
    get :filter
    assert_response :success
    assert          !assigns(:category_groups).blank?
    assert_equal    CategoryGroup.order("name ASC").to_a,            assigns(:category_groups)
    assert          !assigns(:occasions).blank?
    assert_equal    Occasion.search({ :from_date => Date.today - 1 }, nil), assigns(:occasions)

    # Events
    get :filter, :list => "events"
    assert_response :success
    assert          !assigns(:category_groups).blank?
    assert_equal    CategoryGroup.order("name ASC").to_a,                  assigns(:category_groups)
    assert          !assigns(:events).blank?
    assert_equal    Event.search_standing({ :from_date => Date.today - 1 }, nil), assigns(:events)
  end

  test "apply filter" do
    session[:calendar_filter] = {}

    # Clear filter
    get :apply_filter, :clear_filter => true
    assert_redirected_to :action => "filter", :list => :occasions
    assert_equal(        { :from_date => Date.today }, session[:calendar_filter])

    # defaults
    get :apply_filter, :filter => {}
    assert_redirected_to :action => "filter", :list => :occasions
    assert_nil           session[:calendar_filter][:free_text]
    assert_nil           session[:calendar_filter][:from_date]
    assert_nil           session[:calendar_filter][:to_date]
    assert_equal         -1,         session[:calendar_filter][:from_age]
    assert_equal         -1,         session[:calendar_filter][:to_age]
    assert_equal         false,      session[:calendar_filter][:further_education]
    assert_equal         :unbounded, session[:calendar_filter][:date_span]
    assert_equal         [],         session[:calendar_filter][:categories]

    # Free text
    get :apply_filter, :filter => { :free_text => "free_text" }
    assert_equal "free_text", session[:calendar_filter][:free_text]

    # Ages
    get :apply_filter, :filter => { :from_age => "10", :to_age => "11" }
    assert_equal 10, session[:calendar_filter][:from_age]
    assert_equal 11, session[:calendar_filter][:to_age]

    # Further education
    get :apply_filter, :filter => { :further_education => "1" }
    assert session[:calendar_filter][:further_education]

    get :apply_filter, :filter => { :further_education => "2" }
    assert !session[:calendar_filter][:further_education]
    
    # Dates
    get :apply_filter, :filter => { :from_date => "2013-04-07", :to_date => "2013-04-10" }
    assert_equal Date.new(2013, 4, 7),  session[:calendar_filter][:from_date]
    assert_equal Date.new(2013, 4, 10), session[:calendar_filter][:to_date]

    get :apply_filter, :filter => { :from_date => "13-04-07", :to_date => "13-04-10" }
    assert_nil session[:calendar_filter][:from_date]
    assert_nil session[:calendar_filter][:to_date]

    # Date span
    %w(day week month date).each do |param|
      get :apply_filter, :filter => { :date_span => param }
      assert_equal param.to_sym, session[:calendar_filter][:date_span]
    end

    get :apply_filter, :filter => { :date_span => "zomg" }
    assert_equal :unbounded, session[:calendar_filter][:date_span]

    # Categories
    get :apply_filter, :filter => { :categories => %w(-2, -1, 1, 2) }
    assert_equal [-2, 1, 2], session[:calendar_filter][:categories]
  end

  test "clear filter" do
    session[:calendar_filter] = {}
    get :clear_filter
    assert_redirected_to :action => "filter", :list => :occasions
    assert_equal({ :from_date => Date.today }, session[:calendar_filter])

    session[:calendar_filter] = {}
    get :clear_filter, :list => "events"
    assert_redirected_to :action => "filter", :list => :events
    assert_equal({ :from_date => Date.today }, session[:calendar_filter])
  end

  test "list cache key" do
    @controller.stubs(:session).returns({})
    @controller.instance_variable_set(:@calendar_list, "occasions")
    @controller.stubs(:params).returns(:page => 2)
    
    assert_equal "calendar/list/occasions/not_bookable/2", @controller.send(:list_cache_key)

    user = create(:user, :roles => [roles(:booker)])
    @controller.stubs(:session).returns(:current_user_id => user.id)
    assert_equal "calendar/list/occasions/bookable/2", @controller.send(:list_cache_key)
  end
end
