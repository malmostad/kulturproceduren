require 'test_helper'

class RoleApplicationsHelperTest < ActionView::TestCase
  test "state string" do
    app = RoleApplication.new { |a| a.state = RoleApplication::PENDING }
    assert_equal "Inskickad", state_string(app)
    app.state = RoleApplication::ACCEPTED
    assert_equal "Godkänd", state_string(app)
    app.state = RoleApplication::DENIED
    assert_equal "Nekad", state_string(app)
  end

  test "type string" do
    app = RoleApplication.new
    app.culture_provider = culture_providers(:grona_teatern)
    app.new_culture_provider_name = "New provider"

    app.role = roles(:booker)
    assert_equal "Bokning", type_string(app)
    app.role = roles(:host)
    assert_equal "Evenemangsvärd", type_string(app)
    app.role = roles(:culture_worker)
    assert_equal "Publicering för Gröna teatern", type_string(app)
    app.culture_provider = nil
    assert_equal "Publicering för New provider", type_string(app)
    app.role = roles(:admin)
    assert_nil type_string(app)
  end
end
