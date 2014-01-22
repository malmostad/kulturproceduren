# -*- encoding : utf-8 -*-
require 'test_helper'

class PingControllerTest < ActionController::TestCase
  test "ping" do
    get :ping
    assert_equal "pong", @response.body
    assert       @response.headers["Content-Type"] =~ /\btext\/plain\b/
  end
end
