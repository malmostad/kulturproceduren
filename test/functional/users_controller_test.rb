require_relative '../test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)

    @admin = create(:user, roles: [roles(:admin)])
  end

  test "load user" do
    user = create(:user)
    session[:current_user_id] = user.id
    get :show, id: @admin.id
    assert_equal user, assigns(:user)
  end

  test "index for admin" do
    session[:current_user_id] = @admin.id
    get :index
    assert_response :success
    assert_equal    [@admin],  assigns(:users)
  end
  test "index for coordinator" do
    coordinator               = create(:user, roles: [roles(:coordinator)])
    session[:current_user_id] = coordinator.id

    get :index
    assert_response :success
    assert_equal    [@admin, coordinator].sort_by(&:username),  assigns(:users)
  end
  test "index for others" do
    user                      = create(:user)
    session[:current_user_id] = user.id
    
    get :index
    assert_redirected_to user
  end

  test "apply filter" do
    session[:user_list_filter] = nil
    post :apply_filter,  name: "name"
    assert_redirected_to users_url()
    assert_equal(        { name: "name" }, session[:user_list_filter])

    session[:user_list_filter] = nil
    post :apply_filter
    assert_redirected_to users_url()
    assert_equal(        {}, session[:user_list_filter])

    session[:user_list_filter] = nil
    post :apply_filter,  name: ""
    assert_redirected_to users_url()
    assert_equal(        {}, session[:user_list_filter])

    session[:user_list_filter] = { name: "name"}
    post :apply_filter,  name: "name2", clear: true
    assert_redirected_to users_url()
    assert_equal(        {}, session[:user_list_filter])
  end

  test "show for admin" do
    session[:current_user_id] = @admin.id

    user = create(:user)

    get :show, id: user.id
    assert_response :success
    assert_template "users/show"
    assert_equal    user, assigns(:user)
  end
  test "show for others" do
    user                      = create(:user)
    session[:current_user_id] = user.id

    requested_user = create(:user)

    get :show, id: requested_user.id
    assert_response :success
    assert_template "users/show"
    assert_equal    user, assigns(:user)
  end

  test "grant" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    user = create(:user, roles: [roles(:booker)])

    post :grant, id: user.id, role: "booker"
    assert_redirected_to user
    assert_nil           flash[:notice]

    post :grant, id: user.id, role: "coordinator"
    assert_redirected_to user
    assert_equal         "Användaren tilldelades rättigheter.", flash[:notice]
    assert               user.roles(true).include?(roles(:coordinator))
  end

  test "revoke" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    user = create(:user, roles: [roles(:booker)])

    post :revoke, id: user.id, role: "coordinator"
    assert_redirected_to user
    assert_nil           flash[:notice]

    post :revoke, id: user.id, role: "booker"
    assert_redirected_to user
    assert_equal         "Användarens rättigheter återkallades.", flash[:notice]
    assert               !user.roles(true).include?(roles(:booker))
  end

  test "new" do
    @controller.unstub(:authenticate)

    get :new
    assert_response :success
    assert          assigns(:user).new_record?
  end


  test "create, normal user" do
    @controller.unstub(:authenticate)

    # Invalid
    post :create, user: { username: "foo", password: "foo", password_confirmation: "bar" }
    assert_response :success
    assert          assigns(:user).new_record?
    assert          !assigns(:user).valid?
    assert_nil      assigns(:user).password
    assert_nil      assigns(:user).password_confirmation

    # Valid
    user_attributes = attributes_for(:user)

    post :create, user: user_attributes
    assert_redirected_to controller: "login"
    assert_equal         "Din användare har skapats. Du kan nu logga in med ditt användarnamn och lösenord.", flash[:notice]
    assert_equal         User.last.id, assigns(:user).id
  end
  test "create, admin" do
    session[:current_user_id] = @admin.id

    @controller.unstub(:authenticate)

    # Invalid
    post :create, user: { username: "foo", password: "foo", password_confirmation: "bar" }
    assert_response :success
    assert          assigns(:user).new_record?
    assert          !assigns(:user).valid?
    assert_nil      assigns(:user).password
    assert_nil      assigns(:user).password_confirmation

    # Valid
    user_attributes = attributes_for(:user)

    post :create, user: user_attributes
    assert_redirected_to User.last
    assert_equal         "Användaren skapades. Den kan nu logga in med användarnamn och lösenord.", flash[:notice]
  end
  test "create, ldap username taken" do
    APP_CONFIG.replace(salt_length: 4, ldap: { username_prefix: "ldap_" })

    @controller.unstub(:authenticate)

    @controller.expects(:ldap_user_exists).with("foo").returns false

    post :create, user: { username: "foo", password: "foo", password_confirmation: "bar" }

    assert_response :success
    assert          assigns(:user).new_record?
    assert          !assigns(:user).valid?
    assert_nil      assigns(:user).password
    assert_nil      assigns(:user).password_confirmation
  end

  test "update" do
    user                      = create(:user, username: "old_username", name: "old name")
    session[:current_user_id] = user.id

    # Invalid
    put :update, id: user.id, user: { name: ""}
    assert_response :success
    assert_template "users/show"
    assert_equal    user,      assigns(:user)

    # Valid
    put(:update,
      id: user.id,
      user: {
        name: "new name",
        username: "new_username",
        email: "a@b.com",
        cellphone: "123"
      }
    )
    assert_redirected_to user
    assert_equal         "Användaren uppdaterades.", flash[:notice]
    assert_equal         "new name",                 user.reload.name
    assert_equal         "old_username",             user.reload.username
  end

  test "update password, normal user" do
    user = create(:user, password: "foo")
    session[:current_user_id] = user.id

    # Wrong current password
    patch :update_password, id: user.id, user: { current_password: "bar", password: "bar", password_confirmation: "baz" }
    assert_redirected_to user
    assert_equal         "Felaktigt lösenord.", flash[:warning]

    # Empty password
    patch :update_password, id: user.id, user: { current_password: "foo", password: "", password_confirmation: "baz" }
    assert_redirected_to user
    assert_equal         "Lösenordet får inte vara tomt.", flash[:warning]

    # Confirmation not matching password
    patch :update_password, id: user.id, user: { current_password: "foo", password: "bar", password_confirmation: "baz" }
    assert_redirected_to user
    assert_equal         "Lösenordsbekräftelsen matchar inte.", flash[:warning]

    # OK
    patch :update_password, id: user.id, user: { current_password: "foo", password: "bar", password_confirmation: "bar" }
    assert_redirected_to user
    assert_equal         "Lösenordet uppdaterades.", flash[:notice]
  end
  test "update password, admin" do
    user = create(:user, password: "foo")
    session[:current_user_id] = @admin.id

    # Empty password
    put :update_password, id: user.id, user: { password: "", password_confirmation: "baz" }
    assert_redirected_to user
    assert_equal         "Lösenordet får inte vara tomt.", flash[:warning]

    # Confirmation not matching password
    put :update_password, id: user.id, user: { password: "bar", password_confirmation: "baz" }
    assert_redirected_to user
    assert_equal         "Lösenordsbekräftelsen matchar inte.", flash[:warning]

    # OK
    put :update_password, id: user.id, user: { password: "bar", password_confirmation: "bar" }
    assert_redirected_to user
    assert_equal         "Lösenordet uppdaterades.", flash[:notice]
  end

  test "destroy" do
    @controller.expects(:require_admin).at_least_once.returns(true)
    user = create(:user)
    delete :destroy, id: user.id
    assert_redirected_to users_url()
    assert_nil           User.where(id: user.id).first
  end

  test "add culture provider" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    culture_provider = create(:culture_provider)
    user             = create(:user)
    user.culture_providers << culture_provider

    post :add_culture_provider, id: user.id, culture_provider_id: culture_provider.id
    assert_redirected_to user
    assert_nil           flash[:notice]

    user.culture_providers.clear

    post :add_culture_provider, id: user.id, culture_provider_id: culture_provider.id
    assert_redirected_to user
    assert_equal         "Användarens rättigheter uppdaterades.", flash[:notice]
    assert               user.culture_providers(true).include?(culture_provider)
  end

  test "remove culture provider" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    culture_provider = create(:culture_provider)
    user             = create(:user)

    post :remove_culture_provider, id: user.id, culture_provider_id: culture_provider.id
    assert_redirected_to user
    assert_nil           flash[:notice]

    user.culture_providers << culture_provider

    post :remove_culture_provider, id: user.id, culture_provider_id: culture_provider.id
    assert_redirected_to user
    assert_equal         "Användarens rättigheter uppdaterades.", flash[:notice]
    assert               !user.culture_providers(true).include?(culture_provider)
  end

  test "request password reset" do
    @controller.unstub(:authenticate)
    get :request_password_reset
    assert_response :success
    assert          assigns(:user).new_record?
  end

  test "send password reset confirmation" do
    @controller.unstub(:authenticate)

    # Neither username nor password
    post :send_password_reset_confirmation, user: {}
    assert_redirected_to request_password_reset_users_url()
    assert_equal         "Du måste ange ett användarnamn eller en epostadress.", flash[:warning]

    # No user found
    post :send_password_reset_confirmation, user: { username: "does not exist" }
    assert_redirected_to request_password_reset_users_url()
    assert_equal         "Användaren finns inte i systemet.", flash[:warning]


    mailer_mock = stub(deliver: true)
    mailer_mock.expects(:deliver).twice

    # User found by username
    user = create(:user)
    UserMailer.expects(:password_reset_confirmation_email).with(user).returns(mailer_mock)
    assert_nil user.request_key

    post :send_password_reset_confirmation, user: { username: user.username }
    assert_redirected_to root_url()
    assert_equal         "Ett bekräftelsemeddelande har nu skickats till den epostadress som är angiven i användarkontot. Lösenordet återställs först efter att du har följt instruktionerna i meddelandet.", flash[:notice]
    assert               !user.reload.request_key.nil?

    # User found by username
    user = create(:user)
    UserMailer.expects(:password_reset_confirmation_email).with(user).returns(mailer_mock)
    assert_nil user.request_key

    post :send_password_reset_confirmation, user: { email: user.email }
    assert_redirected_to root_url()
    assert_equal         "Ett bekräftelsemeddelande har nu skickats till den epostadress som är angiven i användarkontot. Lösenordet återställs först efter att du har följt instruktionerna i meddelandet.", flash[:notice]
    assert               !user.reload.request_key.nil?
  end

  test "reset password" do
    @controller.unstub(:authenticate)

    user = create(:user, password: "foo")
    user.generate_request_key()
    user.save!

    # Wrong request key
    put :reset_password, id: user.id, key: "abc"
    assert_redirected_to root_url()
    assert_equal         "Felaktig förfrågan.", flash[:warning]

    mailer_mock = stub(deliver: true)
    mailer_mock.expects(:deliver)

    # Correct request key
    UserMailer.expects(:password_reset_email).with(user, anything()).returns(mailer_mock)

    put :reset_password, id: user.id, key: user.request_key
    assert_redirected_to controller: "login", action: "index"
    assert_equal         "Ditt nya lösenord har skickats till din epost.", flash[:notice]
    assert               !User.find(user.id).authenticate("foo")
  end
end
