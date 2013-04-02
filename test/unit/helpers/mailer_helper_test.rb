require 'test_helper'

class MailerHelperTest < ActionView::TestCase
  test "mail url" do
    old_app_config = APP_CONFIG
    Kernel::silence_warnings { ::APP_CONFIG = { :kp_external_link => "test" } }
    assert_equal "test?goto=%2Flogin", mail_url("/login")
    Kernel::silence_warnings { ::APP_CONFIG = old_app_config }
  end
end
