require_relative '../test_helper'

class LoginControllerTest < ActionController::TestCase
  def setup
    session[:current_user_id] = nil
  end

  test "index" do
    session[:return_to] = nil

    get :index
    assert_response :success
    assert_nil      session[:return_to]

    get :index, return_to: "/foo/bar"
    assert_response :success
    assert_equal    "/foo/bar", session[:return_to]
  end
  test "index, user online" do
    session[:current_user_id] = create(:user).id
    get :index
    assert_redirected_to root_url()
  end

  test "login, user online" do
    session[:current_user_id] = create(:user).id
    post :login
    assert_redirected_to root_url()
  end
  test "login, auth failed" do
    # Auth failed
    post :login, user: { username: "invalid", password: "invalid" }
    assert_response :success
    assert_template "login/index"
    assert_equal    "Felaktigt användarnamn/lösenord", flash[:warning]
  end
  test "login, no roles" do
    user = create(:user, last_active: nil, username: "testuser", password: "zomg", roles: [])

    post :login, user: { username: "testuser", password: "zomg" }

    assert_redirected_to role_applications_url()
    assert_equal         "Du är nu inloggad", flash[:notice]
    assert_equal         "Du har för tillfället inga behörigheter i systemet. Var god ansök om behörigheter nedan.", flash[:warning]
    assert_equal         user.id,             session[:current_user_id]
    assert_not_nil       user.reload.last_active
  end
  test "login, return to" do
    session[:return_to] = "/foo/bar"
    user = create(:user, last_active: nil, username: "testuser", password: "zomg", roles: [roles(:admin)])

    post :login, user: { username: "testuser", password: "zomg" }

    assert_redirected_to "/foo/bar"
    assert_nil           session[:return_to]
  end
  test "login, normal user" do
    user = create(:user, last_active: nil, username: "testuser", password: "zomg", roles: [roles(:admin)])

    post :login, user: { username: "testuser", password: "zomg" }

    assert_redirected_to root_url()
    assert_equal         "Du är nu inloggad", flash[:notice]
    assert_nil           flash[:warning]
    assert_equal         user.id,             session[:current_user_id]
    assert_not_nil       user.reload.last_active
  end

  test "logout" do
    get :logout
    assert_redirected_to action: "index"

    session[:current_user_id] = create(:user).id

    get :logout
    assert_redirected_to root_url()
    assert_equal         "Du är nu utloggad.", flash[:notice]
    assert_nil           session[:current_user_id]
  end

  test "session fix" do
    @request.session_options[:key]    = "testcookie"
    @request.cookies["testcookie"]    = "zomg"
    @request.session_options[:path]   = "/foo/bar"
    @request.session_options[:domain] = "example.com"
    @request.session_options[:secure] = true

    expected = {
      name: "testcookie",
      value: "zomg",
      options: {
        path: "/foo/bar",
        domain: "example.com",
        secure: true
      }
    }

    get :session_fix
    assert_response :success
    assert          @response.headers["Content-Type"] =~ /\bapplication\/json\b/
    assert_equal    expected.to_json, @response.body
  end
end
