# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class RoleApplicationsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)

    @user  = create(:user, :roles => [])
    @admin = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @admin.id
  end

  test "index, admin" do
    role_applications = create_list(:role_application, 2, :state => RoleApplication::PENDING).sort_by(&:created_at)
    create_list(:role_application, 2, :state => RoleApplication::ACCEPTED) # dummies

    get :index
    assert_response :success
    assert_equal    role_applications, assigns(:applications)
  end
  test "index, other users" do
    session[:current_user_id] = @user.id
    culture_providers         = create_list(:culture_provider, 3).sort_by(&:name)

    get :index
    assert_response :success
    assert_equal    culture_providers, assigns(:culture_providers)
    assert          assigns(:booker_appl).new_record?
    assert          assigns(:culture_worker_appl).new_record?
    assert          assigns(:host_appl).new_record?
    assert_equal    roles(:booker),         assigns(:booker_appl).role
    assert_equal    roles(:culture_worker), assigns(:culture_worker_appl).role
    assert_equal    roles(:host),           assigns(:host_appl).role
  end

  test "archive" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    role_applications = create_list(:role_application, 3).sort_by(&:created_at).reverse
    
    get :archive
    assert_response :success
    assert_equal    role_applications, assigns(:applications)
  end

  test "edit" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    # Pending
    role_application = create(:role_application, :state => RoleApplication::PENDING)

    get :edit, :id => role_application.id
    assert_response :success
    assert_equal    role_application, assigns(:application)

    # Accepted
    role_application = create(:role_application, :state => RoleApplication::ACCEPTED)

    get :edit, :id => role_application.id
    assert_redirected_to :action => "archive"
    assert_equal         "Behörighetsansökan är redan besvarad", flash[:warning]
  end

  test "create, for admin" do
    post :create
    assert_redirected_to :action => "index"
    assert_equal         "Du har redan administratörsbehörigheter och kan därför inte ansöka om behörigheter.", flash[:notice]
  end
  test "create, for user, valid" do
    session[:current_user_id] = @user.id

    post :create, :role_application => { :role_id => roles(:host).id }

    assert_redirected_to @user
    assert_equal         "Din ansökan har skickats till administratörerna.", flash[:notice]
    assert_equal         @user,                    RoleApplication.last.user
    assert_equal         RoleApplication::PENDING, RoleApplication.last.state
  end
  test "create, for user, invalid" do
    session[:current_user_id] = @user.id
    culture_providers         = create_list(:culture_provider, 3).sort_by(&:name)

    RoleApplication.any_instance.stubs(:valid?).returns(false)

    # booker
    post :create, :role_application => { :role_id => roles(:booker).id }
    assert_response :success
    assert_template "role_applications/index"
    assert_equal    :booker,                assigns(:application_type)
    assert_equal    roles(:booker),         assigns(:booker_appl).role
    assert_equal    roles(:culture_worker), assigns(:culture_worker_appl).role
    assert_equal    roles(:host),           assigns(:host_appl).role
    assert_equal    assigns(:booker_appl),  assigns(:application)
    assert_equal    culture_providers,      assigns(:culture_providers)
    # culture_worker
    post :create, :role_application => { :role_id => roles(:culture_worker).id }
    assert_response :success
    assert_template "role_applications/index"
    assert_equal    :culture_worker,               assigns(:application_type)
    assert_equal    roles(:booker),                assigns(:booker_appl).role
    assert_equal    roles(:culture_worker),        assigns(:culture_worker_appl).role
    assert_equal    roles(:host),                  assigns(:host_appl).role
    assert_equal    assigns(:culture_worker_appl), assigns(:application)
    assert_equal    culture_providers,             assigns(:culture_providers)
    # host
    post :create, :role_application => { :role_id => roles(:host).id }
    assert_response :success
    assert_template "role_applications/index"
    assert_equal    :host,                  assigns(:application_type)
    assert_equal    roles(:booker),         assigns(:booker_appl).role
    assert_equal    roles(:culture_worker), assigns(:culture_worker_appl).role
    assert_equal    roles(:host),           assigns(:host_appl).role
    assert_equal    assigns(:host_appl),    assigns(:application)
    assert_equal    culture_providers,      assigns(:culture_providers)
  end

  test "update, invalid" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    role_application = create(:role_application, :state => RoleApplication::PENDING)

    RoleApplication.any_instance.stubs(:valid?).returns(false)

    put :update, :id => role_application.id, :role_application => { :state => RoleApplication::DENIED }

    assert_response :success
    assert_template "role_applications/edit"
    assert_equal    role_application, assigns(:application)
  end
  test "update, accepted" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    # basic
    role_application = create(:role_application, :state => RoleApplication::PENDING, :role => roles(:host))
    assert role_application.user.roles(true).blank?

    put :update, :id => role_application.id, :role_application => { :state => RoleApplication::ACCEPTED }

    assert_redirected_to :action => "index"
    assert_equal         "Ansökan besvarades.",     flash[:notice]
    assert_equal         RoleApplication::ACCEPTED, role_application.reload.state
    assert               role_application.user.roles(true).include?(roles(:host))
    assert               role_application.user.culture_providers(true).blank?

    # culture worker, existing culture provider
    culture_provider = create(:culture_provider)
    role_application = create(
      :role_application,
      :state => RoleApplication::PENDING,
      :role => roles(:culture_worker),
      :culture_provider => culture_provider
    )
    assert role_application.user.roles(true).blank?
    assert role_application.user.culture_providers(true).blank?

    put :update, :id => role_application.id, :role_application => { :state => RoleApplication::ACCEPTED }

    assert_redirected_to :action => "index"
    assert_equal         "Ansökan besvarades.",     flash[:notice]
    assert_equal         RoleApplication::ACCEPTED, role_application.reload.state
    assert               role_application.user.roles(true).include?(roles(:culture_worker))
    assert               role_application.user.culture_providers(true).include?(culture_provider)

    # culture worker, new culture provider
    culture_provider = create(:culture_provider)
    role_application = create(
      :role_application,
      :state => RoleApplication::PENDING,
      :role => roles(:culture_worker),
      :culture_provider => nil,
      :new_culture_provider_name => "zomg"
    )
    assert role_application.user.roles(true).blank?
    assert role_application.user.culture_providers(true).blank?

    put :update, :id => role_application.id, :role_application => { :state => RoleApplication::ACCEPTED }

    assert_redirected_to :action => "index"
    assert_equal         "Ansökan besvarades.",     flash[:notice]
    assert_equal         RoleApplication::ACCEPTED, role_application.reload.state
    assert_equal         "zomg",                    CultureProvider.last.name
    assert               role_application.user.roles(true).include?(roles(:culture_worker))
    assert               role_application.user.culture_providers(true).include?(CultureProvider.last)
  end
  test "update, denied" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    role_application = create(:role_application, :state => RoleApplication::PENDING)

    put :update, :id => role_application.id, :role_application => { :state => RoleApplication::DENIED }

    assert_redirected_to :action => "index"
    assert_equal         "Ansökan besvarades.",   flash[:notice]
    assert_equal         RoleApplication::DENIED, role_application.reload.state
  end
  
end
