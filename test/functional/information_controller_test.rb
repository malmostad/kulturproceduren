# -*- encoding : utf-8 -*-
require 'test_helper'

class InformationControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)
  end

  test "new" do
    get :new
    assert_response :success
    assert          assigns(:mail).is_a?(UtilityModels::InformationMail)
    assert_nil      assigns(:event)
    assert_nil      assigns(:mail).recipients

    event = create(:event)
    get :new, :event_id => event.id
    assert_response :success
    assert          assigns(:mail).is_a?(UtilityModels::InformationMail)
    assert_equal    event,    assigns(:event)
    assert_equal    event.id, assigns(:mail).recipients
  end

  test "create, invalid" do
    post :create, :information_mail => {}
    assert_response :success
    assert_template "information/new"
    assert          !assigns(:mail).valid?
  end
  test "create, all users" do
    mailer_mock = stub(:deliver => true)
    mailer_mock.expects(:deliver).times(3)

    create_list(:user, 3).each do |user|
      InformationMailer.expects(:custom_email).with(user.email, "Subject", "Body").returns(mailer_mock)
    end

    post :create, :information_mail => { :recipients => "all_users", :subject => "Subject", :body => "Body" }
    assert_redirected_to :action => "new"
    assert_equal         "E-post skickat till alla användare (3 mottagare)", flash[:notice]
  end
  test "create, all contacts" do
    contacts = 1.upto(8).collect { |i| "contact#{i}" }

    mailer_mock = stub(:deliver => true)
    mailer_mock.expects(:deliver).times(8)

    district1 = create(:district, :contacts => "#{contacts[0]},#{contacts[1]}")
    district2 = create(:district, :contacts => contacts[2])
    school1   = create(:school,   :district => district1, :contacts => contacts[3])
    school2   = create(:school,   :district => district1, :contacts => contacts[4])
    group1    = create(:group,    :school => school1,     :contacts => contacts[5])
    group2    = create(:group,    :school => school1,     :contacts => "#{contacts[6]},#{contacts[7]}")

    contacts.each { |c| InformationMailer.expects(:custom_email).with(c, "Subject", "Body").returns(mailer_mock) }

    post :create, :information_mail => { :recipients => "all_contacts", :subject => "Subject", :body => "Body" }
    assert_redirected_to :action => "new"
    assert_equal         "E-post skickat till alla kontakter (8 mottagare)", flash[:notice]
  end
  test "create, booked users" do
    event = create(
      :event_with_occasions,
      :occasion_count => 2,
      :occasion_dates => [Date.today - 1],
      :name => "Event",
      :ticket_state => :free_for_all
    )
    create(:allotment, :event => event, :amount => 10)

    user1 = create(:user)
    user2 = create(:user)
    create(:user)

    create(:booking, :occasion => event.occasions.first,  :user => user2, :companion_email => "companion1", :student_count => 1, :adult_count => 0, :wheelchair_count => 0)
    create(:booking, :occasion => event.occasions.second, :user => user1, :companion_email => "companion2", :student_count => 1, :adult_count => 0, :wheelchair_count => 0)

    mailer_mock = stub(:deliver => true)
    mailer_mock.expects(:deliver).times(4)

    [
      user1.email,
      user2.email,
      "companion1",
      "companion2"
    ].each { |c| InformationMailer.expects(:custom_email).with(c, "Subject", "Body").returns(mailer_mock) }

    post :create, :information_mail => { :recipients => "#{event.id}", :subject => "Subject", :body => "Body" }
    assert_redirected_to :action => "new"
    assert_equal         "E-post skickat till alla bokade till Event (4 mottagare)", flash[:notice]
  end
end
