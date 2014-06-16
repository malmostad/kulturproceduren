require 'test_helper'

class CultureProvidersControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)

    @user = create(:user, roles: [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "index, admin" do
    @controller.unstub(:authenticate)
    @controller.expects(:authenticate).never

    create_list(:culture_provider, 3)

    get :index

    assert_response :success
    assert_equal    CultureProvider.order("name asc").to_a, assigns(:culture_providers)
  end
  test "index, no admin" do
    @controller.unstub(:authenticate)
    @controller.expects(:authenticate).never

    culture_providers = create_list(:culture_provider, 3)
    create_list(:culture_provider, 3, active: false)
    session[:current_user_id] = nil

    get :index

    assert_response :success
    assert_equal    culture_providers.sort_by(&:name), assigns(:culture_providers)
  end

  test "show" do
    @controller.unstub(:authenticate)
    @controller.expects(:authenticate).never

    culture_provider = create(:culture_provider)

    get :show, id: culture_provider.id

    assert_response :success
    assert_equal    culture_provider,                assigns(:culture_provider)
  end

  test "new" do
    @controller.expects(:require_admin).returns(true)
    get :new
    assert_response :success
    assert_template "culture_providers/edit"
    assert          assigns(:culture_provider).new_record?
  end

  test "edit, unauthorized" do
    culture_provider          = create(:culture_provider)
    user                      = create(:user, roles: [roles(:culture_worker)], culture_providers: [])
    session[:current_user_id] = user.id

    get :edit, id: culture_provider.id
    assert_redirected_to culture_provider
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end
  test "edit, authorized" do
    culture_provider = create(:culture_provider)

    get :edit, id: culture_provider.id

    assert_response :success
    assert_equal    culture_provider, assigns(:culture_provider)
  end

  test "create" do
    @controller.expects(:require_admin).twice.returns(true)

    # Invalid
    post :create, culture_provider: { name: "" }
    assert_response :success
    assert_template "culture_providers/edit"
    assert          !assigns(:culture_provider).valid?

    # Valid
    post :create, culture_provider: { name: "zomg" }
    assert_redirected_to assigns(:culture_provider)
    assert_equal         "Arrangören skapades.", flash[:notice]
    assert_equal         "zomg", assigns(:culture_provider).name
    assert               !assigns(:culture_provider).id.nil?
  end

  test "update" do
    culture_provider = create(:culture_provider, name: "foo")

    # Invalid
    put :update, id: culture_provider.id, culture_provider: { name: "" }
    assert_response :success
    assert_template "culture_providers/edit"
    assert_equal    culture_provider, assigns(:culture_provider)
    assert          !assigns(:culture_provider).valid?

    # Valid
    put :update, id: culture_provider.id, culture_provider: { name: "zomg" }
    assert_redirected_to culture_provider
    assert_equal         "Arrangören uppdaterades.", flash[:notice]
    
    culture_provider.reload
    assert_equal "zomg", culture_provider.name
  end

  test "destroy" do
    @controller.expects(:require_admin).returns(true)
    culture_provider = create(:culture_provider, name: "foo")

    delete :destroy, id: culture_provider.id
    assert_redirected_to culture_providers_url()
    assert_nil           CultureProvider.where(id: culture_provider.id).first
  end

  test "activate" do
    @controller.expects(:require_admin).returns(true)
    culture_provider = create(:culture_provider, active: false)

    get :activate, id: culture_provider.id

    assert_redirected_to culture_provider
    assert_equal         "Arrangören aktiverades.", flash[:notice]

    culture_provider.reload
    assert culture_provider.active
  end

  test "deactivate" do
    @controller.expects(:require_admin).returns(true)
    culture_provider = create(:culture_provider, active: true)

    get :deactivate, id: culture_provider.id

    assert_redirected_to culture_provider
    assert_equal         "Arrangören deaktiverades.", flash[:notice]

    culture_provider.reload
    assert !culture_provider.active
  end
end
