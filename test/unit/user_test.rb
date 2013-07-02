require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "validations" do
    user = build(:user, :username => "")
    assert !user.valid?
    assert user.errors.include?(:username)
    user = build(:user, :password => "")
    assert !user.valid?
    assert user.errors.include?(:password)
    user = build(:user, :name => "")
    assert !user.valid?
    assert user.errors.include?(:name)
    user = build(:user, :email => "")
    assert !user.valid?
    assert user.errors.include?(:email)
    user = build(:user, :email => "foobarbaz")
    assert !user.valid?
    assert user.errors.include?(:email)
    user = build(:user, :cellphone => "")
    assert !user.valid?
    assert user.errors.include?(:cellphone)
    user = build(:user, :password => "foo", :password_confirmation => "bar")
    assert !user.valid?
    assert user.errors.include?(:password)
    user = build(:user, :district_ids => nil)
    assert !user.valid?
    assert user.errors.include?(:district_ids)
  end

  test "groups by occasion" do
    user = create(:user)
    occasions = create_list(:occasion, 2)
    groups = create_list(:group, 3)

    groups.each do |g|
      create_list(:ticket, 3, :occasion => occasions.first, :user => user, :group => g)
    end

    create_list(:group, 3).each do |g|
      create_list(:ticket, 3, :occasion => occasions.second, :user => user, :group => g)
    end

    found_groups = user.groups.find_by_occasion(occasions.first)
    assert_equal 3, found_groups.length
    found_groups.each { |g| assert groups.include?(g) }
  end

  test "filter" do
    districts = create_list(:district, 3)
    create(:user, :districts => districts,          :username => "zap",  :name => "depa")
    create(:user, :districts => districts,          :username => "foo",  :name => "apa")
    create(:user, :districts => districts,          :username => "bazq", :name => "cepa")
    create(:user, :districts => districts,          :username => "barq", :name => "bepa")
    create(:user, :districts => [districts.second], :username => "zab",  :name => "gepaq")
    create(:user, :districts => [districts.second], :username => "paz",  :name => "hepa")
    create(:user, :districts => [districts.first],  :username => "rab",  :name => "fepaq")
    create(:user, :districts => [districts.first],  :username => "oof",  :name => "epa")

    old_per_page = User.per_page
    User.per_page = 3

    # Pagination
    users = User.filter({}, 2, "name asc")
    assert_equal 3, users.length
    assert_equal "depa", users.first.name
    assert_equal "epa", users.second.name
    assert_equal "fepaq", users.third.name

    User.per_page = old_per_page

    # District
    users = User.filter({ :district_id => districts.first.id }, 1, "name asc")
    assert_equal 6, users.length
    users.each { |u| assert u.districts.exists?(:id => districts.first.id) }

    # Name
    users = User.filter({ :name => "q" }, 1, "name asc")
    assert_equal 4, users.length
    users.each { |u| assert u.name =~ /q/ || u.username =~ /q/ }

    # All
    users = User.filter({ :name => "apa", :district_id => districts.first.id }, 1, "name asc")
    assert_equal 1, users.length
    assert_equal "apa", users.first.name
  end

  test "authenticate" do
    user = create(:user, :username => "authtest", :password => "zomg", :password_confirmation => "zomg")
    assert user.authenticate("zomg")
    assert !user.authenticate("fault")

    assert_nil User.authenticate("authtest", "fault")
    assert_nil User.authenticate("authtest2", "zomg")
    assert_equal user.id, User.authenticate("authtest", "zomg").id
  end

  test "get_username" do
    user = create(:user, :username => "username")

    assert_equal "username", user.get_username

    APP_CONFIG.replace(:ldap => { :username_prefix => "ldap_" })
    user.username = "ldap_username"
    assert_equal "username", user.get_username
  end

  test "bookings" do
    user = create(:user)
    occasions = create_list(:occasion, 2)
    groups = create_list(:group, 2)

    occasions.each do |o|
      groups.each do |g|
        create_list(:ticket, 2, :group => g, :occasion => o, :user => user)
      end
    end

    create(:ticket, :occasion => occasions.first)
    create(:ticket, :group    => groups.first)

    bookings = user.bookings
    assert_equal 4, bookings.length
    assert bookings.include?("occasion" => occasions.first,  "group" => groups.first)
    assert bookings.include?("occasion" => occasions.second, "group" => groups.first)
    assert bookings.include?("occasion" => occasions.first,  "group" => groups.second)
    assert bookings.include?("occasion" => occasions.second, "group" => groups.second)
  end

  test "has role" do
    id = create(:user, :roles => [roles(:booker)]).id

    assert User.find(id).has_role?(:booker)
    assert !User.find(id).has_role?(:admin)
    assert User.find(id).has_role?(:admin, :booker)
    assert !User.find(id).has_role?(:admin, :host)
  end

  test "can administrate" do
    culture_providers    = create_list(:culture_provider, 2)
    culture_worker       = create(:user, :roles => [roles(:culture_worker)], :culture_providers => [culture_providers.first])
    blank_culture_worker = create(:user, :roles => [roles(:culture_worker)], :culture_providers => [])
    admin                = create(:user, :roles => [roles(:admin)])
    booker               = create(:user, :roles => [roles(:booker)])

    assert  admin.can_administrate?(culture_providers.first)
    assert  admin.can_administrate?(culture_providers.second)
    assert !admin.can_administrate?(nil)
    assert  culture_worker.can_administrate?(culture_providers.first)
    assert !culture_worker.can_administrate?(culture_providers.second)
    assert !culture_worker.can_administrate?(nil)
    assert !blank_culture_worker.can_administrate?(culture_providers.first)
    assert !blank_culture_worker.can_administrate?(culture_providers.second)
    assert !blank_culture_worker.can_administrate?(nil)
    assert !booker.can_administrate?(culture_providers.first)
    assert !booker.can_administrate?(culture_providers.second)
    assert !booker.can_administrate?(nil)
  end

  test "can book" do
    assert  create(:user, :roles => [roles(:booker)]).can_book?
    assert  create(:user, :roles => [roles(:admin)]).can_book?
    assert !create(:user, :roles => [roles(:host)]).can_book?
    assert !create(:user, :roles => [roles(:culture_worker)]).can_book?
    assert !create(:user, :roles => [roles(:coordinator)]).can_book?
  end

  test "can view bookings" do
    assert  create(:user, :roles => [roles(:booker)]).can_view_bookings?
    assert  create(:user, :roles => [roles(:admin)]).can_view_bookings?
    assert  create(:user, :roles => [roles(:coordinator)]).can_view_bookings?
    assert !create(:user, :roles => [roles(:host)]).can_view_bookings?
    assert !create(:user, :roles => [roles(:culture_worker)]).can_view_bookings?
  end

  test "password handling" do
    user = build(:user, :password => nil, :password_confirmation => nil, :salt => nil)

    assert_nil user.password
    assert_nil user.password_confirmation
    assert_nil user.salt

    user.password = "pass"
    assert_not_nil user.salt
    assert_not_nil user.password
    assert_not_equal "pass", user.password
    assert user.password =~ /^[0-9a-f]{40}$/
    assert user.authenticate("pass")

    user.salt = nil
    user.password_confirmation = "pass"
    assert_not_nil user.salt
    assert_not_nil user.password_confirmation
    assert_not_equal "pass", user.password_confirmation
    assert user.password_confirmation =~ /^[0-9a-f]{40}$/
    user.password = "pass"
    assert_equal user.password, user.password_confirmation

    user.reset_password

    assert_nil user.password
    assert_nil user.password_confirmation
    assert_nil user.salt
  end

  test "generate request key" do
    user = create(:user, :request_key => nil)
    assert_nil user.request_key
    user.generate_request_key
    assert_not_nil user.request_key
  end

  test "generate new password" do
    user = create(:user)
    new_pass = user.generate_new_password
    assert User.authenticate(user.username, new_pass)
  end

  test "username unique" do
    user = create(:user, :username => "username")

    assert !build(:user, :username => "username").valid?

    APP_CONFIG.replace(:salt_length => 10, :ldap => { :username_prefix => "ldap_" })
    assert !build(:user, :username => "ldap_username").valid?
  end
end
