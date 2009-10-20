require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "successful authentication" do
    u = User.authenticate("pelle", "lösenord")

    assert_not_nil u
    assert_equal u.username, "pelle"

    assert User.find(users(:pelle).id).authenticate("lösenord")
  end

  test "invalid password" do
    assert_nil User.authenticate("pelle", "fail")
    assert !User.find(users(:pelle).id).authenticate("fail")
  end

  test "invalid username" do
    assert_nil User.authenticate("notexist", "notexist")
  end

  test "password creation" do
    pass = "passcreatepass"
    u = User.new
    u.username = "passcreateuser"
    u.password = pass
    u.name = "Test"
    u.email = "test@test.com"
    u.cellphone = "0702345678"

    assert u.save

    u2 = User.authenticate(u.username, pass)

    assert_not_nil u2
    assert_equal u2.username, u.username
  end

  test "password generation" do
    u = User.find(users(:pelle).id)
    password = u.generate_new_password

    assert User.authenticate("pelle", password)
  end

  test "unique username" do
    u = User.new
    u.username = "pelle"
    u.password = "pelle"

    assert !u.save
  end


  test "has role successful" do
    u = User.find(users(:pelle).id)
    assert u.has_role?(:admin)
  end

  test "has any role" do
    assert User.find(users(:pelle).id).has_role?(:admin, :culture_worker)
    assert User.find(users(:booker1).id).has_role?(:admin, :culture_worker, :booker)
    assert !User.find(users(:booker1).id).has_role?(:admin, :culture_worker)
  end

  test "has role unsuccessful" do
    assert !User.find(users(:pelle).id).has_role?(:culture_worker)
  end


  test "can administrate culture provider" do
    cp = CultureProvider.find(culture_providers(:grona_teatern).id)

    # admin
    assert User.find(users(:pelle).id).can_administrate?(cp)
    # culture worker
    assert User.find(users(:provider1).id).can_administrate?(cp)
    assert !User.find(users(:provider2).id).can_administrate?(cp)
  end

  test "can book" do
    assert User.find(users(:booker1).id).can_book?
    assert User.find(users(:admin1).id).can_book?
    assert !User.find(users(:provider1).id).can_book?
  end

end
