require_relative '../../test_helper'

class MailerHelperTest < ActionView::TestCase
  test "mail url" do
    APP_CONFIG.replace(kp_external_link: "test")
    assert_equal "test/login", mail_url("/login")
  end
end
