require 'test_helper'

class RoleApplicationsHelperTest < ActionView::TestCase
  include ERB::Util

  test "state string" do
    role_application = build(:role_application, :state => RoleApplication::PENDING)
    assert_equal "Inskickad", state_string(role_application)
    role_application.state = RoleApplication::ACCEPTED
    assert_equal "Godkänd", state_string(role_application)
    role_application.state = RoleApplication::DENIED
    assert_equal "Nekad", state_string(role_application)
  end

  test "type string" do
    role_application = build(:role_application, :culture_provider => create(:culture_provider), :new_culture_provider_name => "New provider")

    role_application.role = roles(:booker)
    assert_equal "Bokning", type_string(role_application)
    role_application.role = roles(:host)
    assert_equal "Evenemangsvärd", type_string(role_application)
    role_application.role = roles(:culture_worker)
    assert_equal "Publicering för #{role_application.culture_provider.name}", type_string(role_application)
    role_application.culture_provider = nil
    assert_equal "Publicering för New provider", type_string(role_application)
    role_application.role = roles(:admin)
    assert_nil type_string(role_application)
  end
end
