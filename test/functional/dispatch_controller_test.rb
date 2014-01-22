# -*- encoding : utf-8 -*-
require 'test_helper'

class DispatchControllerTest < ActionController::TestCase
  test "index, no goto" do
    get                  :index
    assert_redirected_to root_url()
  end
  test "index, without relative url root" do
    assert_nil           ActionController::Base.relative_url_root
    get                  :index, :goto => "/foo/bar"
    assert_redirected_to "/foo/bar"
  end
  test "index, with relative url root" do
    ActionController::Base.stubs(:relative_url_root).returns("/foo")

    get :index, :goto => "/bar"
    assert_redirected_to "/foo/bar"

    get :index, :goto => "/foo/bar"
    assert_redirected_to "/foo/bar"
  end
end
