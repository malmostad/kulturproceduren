require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "successful authentication" do
    u = User.authenticate("foo", "foopass")

    assert_not_nil u
    assert_equal u.username, "foo"
  end

  test "invalid password" do
    u = User.authenticate("foo", "fail")
    assert_nil u
  end

  test "invalid username" do
    u = User.authenticate("notexist", "notexist")
    assert_nil u
  end

  test "successful instance authentication" do
    u = User.find users(:foo).id
    assert u.authenticate("foopass")
  end

  test "unsuccessful instance authentication" do
    u = User.find users(:foo).id
    assert !u.authenticate("error")
  end


  test "password creation" do
    pass = "passcreatepass"
    u = User.new
    u.username = "passcreateuser"
    u.password = pass
    u.name = "Test"
    u.email = "test@test.com"
    u.mobil_nr = "0702345678"

    assert u.save

    u2 = User.authenticate(u.username, pass)

    assert_not_nil u2
    assert_equal u2.username, u.username
  end

  test "unique username" do
    u = User.new
    u.username = "foo"
    u.password = "foo"

    assert !u.save
  end


  test "has role successful" do
    u = User.find users(:foo).id
    assert u.has_role?(:admin)
  end

  test "has role unsuccessful" do
    u = User.find users(:foo).id
    assert !u.has_role?(:culture_worker)
  end


  test "can administrate culture provider" do
    cp = CultureProvider.find culture_providers(:foo)

    # admin
    assert User.find(users(:foo).id).can_administrate?(cp)
    # culture worker
    assert User.find(users(:provider1).id).can_administrate?(cp)
    assert !User.find(users(:provider2).id).can_administrate?(cp)
  end
  
end
