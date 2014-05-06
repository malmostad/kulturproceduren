# -*- encoding : utf-8 -*-
require 'test_helper'

class MailerHelperTest < ActionView::TestCase
  test "mail url" do
    APP_CONFIG.replace(kp_external_link: "test")
    assert_equal "test?goto=%2Flogin", mail_url("/login")
  end
end
