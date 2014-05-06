require 'test_helper'

class BookingsControllerTest < ActionController::TestCase
  def setup
    # Stub ActionController filters
    @controller.expects(:authenticate).at_least_once.returns(true)

    @event = create(
      :event_with_occasions,
      ticket_state: :free_for_all,
      occasion_count: 3,
      occasion_dates: [ Date.today - 1, Date.today + 1, Date.today + 2 ]
    )
    create(:allotment, event: @event, amount: 10)

    @group = create(:group)

    @user  = create(:user, roles: [roles(:booker)])
    session[:current_user_id] = @user.id
  end

  def book(group, occasion, student_count, adult_count = 0, wheelchair_count = 0, options = {})
    create(
      :booking,
      options.merge(group: group,
        occasion: occasion,
        student_count: student_count,
        adult_count: adult_count,
        wheelchair_count: wheelchair_count,
        user: @user
      )
    )
  end

  test "require booker with normal user" do
    session[:current_user_id] = create(:user).id
    get :form
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    get :new
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    post :create
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    get :edit
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    put :update
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    post :destroy
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
  end
  test "require booker with coordinator user" do
    session[:current_user_id] = create(:user, roles: [roles(:coordinator)]).id
    get :form
    assert_redirected_to action: "group"
    get :new
    assert_redirected_to action: "group"
    post :create
    assert_redirected_to action: "group"
    get :edit
    assert_redirected_to action: "group"
    put :update
    assert_redirected_to action: "group"
    post :destroy
    assert_redirected_to action: "group"
  end
  test "require viewer" do
    session[:current_user_id] = create(:user).id
    get :index
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    post :apply_filter
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    get :group
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    get :group_list
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    get :show
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "load booking for change, inactive booking" do
    booking = book(@group, @event.occasions.second, 1, 0, 0, unbooked: true)

    get :edit, id: booking.id
    assert_response 404

    put :update, id: booking.id
    assert_response 404

    post :unbook, id: booking.id
    assert_response 404

    delete :destroy, id: booking.id
    assert_response 404
  end
  test "load booking for change, cancelled occasion" do
    occasion = @event.occasions.second
    occasion.cancelled = true
    occasion.save

    booking = book(@group, occasion, 1)

    get :edit, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
    put :update, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
    post :unbook, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
    delete :destroy, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
  end
  test "load booking for change, passed occasion" do
    booking = book(@group, @event.occasions.first, 1)

    get :edit, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
    put :update, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
    post :unbook, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
    delete :destroy, id: booking.id
    assert_redirected_to booking_url(booking)
    assert_equal "Du kan inte ändra en bokning på en föreställning som blivit inställd eller som redan har varit", flash[:warning]
    assert_equal booking, assigns(:booking)
  end

  test "index" do
    session[:booking_list_filter] = {}

    dummy_occasion = create(:occasion)
    bookings = [
      book(@group, @event.occasions.first,  1),
      book(@group, @event.occasions.second, 1),
      book(@group, dummy_occasion,          1)
    ]
    unbooked = book(@group, @event.occasions.first, 1, 0, 0, unbooked: true, unbooked_at: Date.today)

    # No district or occasion
    get :index
    assert_equal bookings.length, assigns(:bookings).length
    assigns(:bookings).each { |b| assert bookings.include?(b) }

    # Occasion id
    get :index, occasion_id: @event.occasions.second.id
    assert_equal [bookings.second], assigns(:bookings)
    assert_equal District.order("name asc").to_a, assigns(:districts)

    # Event id
    get :index, event_id: @event.id
    assert_equal 3, assigns(:bookings).length
    assigns(:bookings).each { |b| assert [bookings.first, bookings.second, unbooked].include?(b) }
    assert_equal District.order("name asc").to_a, assigns(:districts)

    # Booking list filter
    session[:booking_list_filter] = {
      unbooked: false
    }
    get :index, event_id: @event.id
    assert_equal 2, assigns(:bookings).length
    assigns(:bookings).each { |b| assert [bookings.first, bookings.second].include?(b) }

    session[:booking_list_filter] = {
      district_id: create(:district).id
    }

    get :index, occasion_id: @event.occasions.first.id
    assert assigns(:bookings).blank?
  end

  test "bus" do
    @controller.expects(:require_admin).at_least_once.returns(true)

    booking = book(@group, @event.occasions.first, 1, 1, 1, bus_booking: true, bus_stop: "foo")

    book(@group, create(:occasion),      1, 1, 1, bus_booking: true, bus_stop: "foo")
    book(@group, @event.occasions.first, 1, 1, 1, bus_booking: false)

    get :bus, event_id: @event.id
    assert_equal @event,    assigns(:event)
    assert_equal [booking], assigns(:bookings)
  end

  test "apply filter" do
    occasion = create(:occasion)

    # Redirects
    post :apply_filter, occasion_id: occasion.id
    assert_redirected_to occasion_bookings_url(occasion.id)
    post :apply_filter, event_id: occasion.event.id
    assert_redirected_to event_bookings_url(occasion.event.id)

    # district_id
    session[:booking_list_filter] = nil
    post :apply_filter, occasion_id: occasion.id, district_id: "42"
    assert_equal 42, session[:booking_list_filter][:district_id]

    session[:booking_list_filter] = nil
    post :apply_filter, occasion_id: occasion.id
    assert_nil session[:booking_list_filter][:district_id]

    session[:booking_list_filter] = nil
    post :apply_filter, occasion_id: occasion.id, district_id: 0
    assert_nil session[:booking_list_filter][:district_id]

    # unbooked
    session[:booking_list_filter] = nil
    post :apply_filter, occasion_id: occasion.id
    assert session[:booking_list_filter][:unbooked] == false

    session[:booking_list_filter] = nil
    post :apply_filter, occasion_id: occasion.id, unbooked: ""
    assert session[:booking_list_filter][:unbooked] == false

    session[:booking_list_filter] = nil
    post :apply_filter, occasion_id: occasion.id, unbooked: "1"
    assert session[:booking_list_filter][:unbooked] == true
  end

  test "group" do
    # No group loaded
    session[:group_selection] = nil
    get :group
    assert_nil assigns(:bookings)
    assert_nil assigns(:group)

    booked = book(@group, @event.occasions.first, 1)
    book(@group,          @event.occasions.first, 1, 0, 0, unbooked: true, unbooked_at: Date.today)
    book(create(:group),  @event.occasions.first, 1)

    # Group loaded by parameter
    session[:group_selection] = nil
    get :group, group_id: @group.id
    assert_equal @group,                    assigns(:group)
    assert_equal @group.school.district_id, session[:group_selection][:district_id]
    assert_equal @group.school.id,          session[:group_selection][:school_id]
    assert_equal @group.id,                 session[:group_selection][:group_id]
    assert_equal [booked],                  assigns(:bookings)

    # Group loaded by session selection
    session[:group_selection] = { group_id: @group.id }
    get :group
    assert_equal @group,   assigns(:group)
    assert_equal [booked], assigns(:bookings)
  end

  test "group list" do
    booked = book(@group, @event.occasions.first, 1)
    book(@group,          @event.occasions.first, 1, 0, 0, unbooked: true, unbooked_at: Date.today)
    book(create(:group),  @event.occasions.first, 1)

    get :group_list, group_id: @group.id
    assert_response :success
    assert_template "bookings/_list"
    assert_equal @group,   assigns(:group)
    assert_equal [booked], assigns(:bookings)
  end

  test "show for booker" do
    booked   = book(@group, @event.occasions.first, 1)
    unbooked = book(@group, @event.occasions.first, 1, 0, 0, unbooked: true, unbooked_at: Date.today)

    # 404
    get :show, id: -1
    assert_redirected_to bookings_url()
    assert_equal "Klassen/avdelningen har ingen bokning på den efterfrågade föreställningen.", flash[:warning] 

    # Normal booking
    get :show, id: booked.id
    assert_response :success
    assert_equal booked, assigns(:booking)

    # Unbooked, no admin
    get :show, id: unbooked.id
    assert_redirected_to bookings_url()
    assert_equal "Klassen/avdelningen har ingen bokning på den efterfrågade föreställningen.", flash[:warning] 
  end
  test "show for admin" do
    unbooked = book(@group, @event.occasions.first, 1, 0, 0, unbooked: true, unbooked_at: Date.today, unbooked_by: @user)

    # Unbooked, admin
    admin = create(:user, roles: [roles(:admin)])
    session[:current_user_id] = admin.id
    get :show, id: unbooked.id
    assert_response :success
    assert_equal unbooked, assigns(:booking)
  end

  test "form with existing booking" do
    booking = book(@group, @event.occasions.first, 1)

    get :form, group_id: @group.id, occasion_id: @event.occasions.first.id
    assert_response :success
    assert_template "bookings/_form"
    assert_equal @group,                 assigns(:group)
    assert_equal @event.occasions.first, assigns(:occasion)
    assert_equal booking,                assigns(:booking)
    assert assigns(:is_edit)
  end
  test "form without existing booking" do
    booking = book(@group, @event.occasions.first, 1)
    booking.unbook!(@user)

    get :form, group_id: @group.id, occasion_id: @event.occasions.first.id
    assert_response :success
    assert_template "bookings/_form"
    assert_equal @group,                 assigns(:group)
    assert_equal @event.occasions.first, assigns(:occasion)
    assert !assigns(:is_edit)

    assert assigns(:booking).new_record?
    assert_equal @group.id,                 assigns(:booking).group_id
    assert_equal @event.occasions.first.id, assigns(:booking).occasion_id
  end

  test "new without group" do
    occasion = create(:occasion)

    get :new, occasion_id: occasion.id

    assert_response :success
    assert_equal    occasion, assigns(:occasion)
    assert_nil      assigns(:group)
    assert_nil      assigns(:booking)
  end
  test "new without booking" do
    occasion = create(:occasion)
    groups   = create_list(:group, 2)

    assert_nil session[:group_selection]

    # No group by group selection
    get :new, occasion_id: occasion.id, group_id: groups.first.id

    assert_response :success
    assert_equal    occasion,     assigns(:occasion)
    assert_equal    groups.first, assigns(:group)
    assert          assigns(:booking).new_record?
    assert_equal    groups.first, assigns(:booking).group
    assert_equal    occasion,     assigns(:booking).occasion

    assert_equal    groups.first.id,                 session[:group_selection][:group_id]
    assert_equal    groups.first.school.id,          session[:group_selection][:school_id]
    assert_equal    groups.first.school.district.id, session[:group_selection][:district_id]

    # Group selection exists, no group id
    get :new, occasion_id: occasion.id

    assert_response :success
    assert_equal    occasion,     assigns(:occasion)
    assert_equal    groups.first, assigns(:group)
    assert          assigns(:booking).new_record?
    assert_equal    groups.first, assigns(:booking).group
    assert_equal    occasion,     assigns(:booking).occasion

    assert_equal    groups.first.id,                 session[:group_selection][:group_id]
    assert_equal    groups.first.school.id,          session[:group_selection][:school_id]
    assert_equal    groups.first.school.district.id, session[:group_selection][:district_id]

    # Group selection exists, override by group id
    get :new, occasion_id: occasion.id, group_id: groups.second.id

    assert_response :success
    assert_equal    occasion,      assigns(:occasion)
    assert_equal    groups.second, assigns(:group)
    assert          assigns(:booking).new_record?
    assert_equal    groups.second, assigns(:booking).group
    assert_equal    occasion,      assigns(:booking).occasion

    assert_equal    groups.second.id,                 session[:group_selection][:group_id]
    assert_equal    groups.second.school.id,          session[:group_selection][:school_id]
    assert_equal    groups.second.school.district.id, session[:group_selection][:district_id]
  end
  test "new with booking" do
    occasion = create(:occasion)
    group    = create(:group)
    booking  = create(:booking, occasion: occasion, group: group)

    get :new, occasion_id: occasion.id, group_id: group.id
    assert_redirected_to edit_booking_url(booking)

    booking.unbook!(create(:user))

    get :new, occasion_id: occasion.id, group_id: group.id
    assert_response :success
  end

  test "create with invalid booking" do
    occasion = create(:occasion)
    group    = create(:group)

    post :create, booking: { group_id: group.id, occasion_id: occasion.id }
    assert_response :success
    assert          assigns(:booking).new_record?
    assert          !assigns(:booking).valid?
    assert_equal    @user,    assigns(:booking).user
    assert_equal    group,    assigns(:booking).group
    assert_equal    group,    assigns(:group)
    assert_equal    occasion, assigns(:booking).occasion
    assert_equal    occasion, assigns(:occasion)
    assert_template "bookings/new"
  end
  test "create with valid booking" do
    occasion             = create(:occasion)
    group                = create(:group)
    # Notification request that's supposed to be removed
    notification_request = create(
      :notification_request,
      user: @user,
      event: occasion.event,
      target_cd: NotificationRequest.targets.for_unbooking
    )
    # Tickets to allow the booking validation to go through
    create_list(
      :ticket,
      10,
      booking: nil,
      group: group,
      district: group.school.district,
      occasion: occasion,
      event: occasion.event,
      state: :unbooked
    )

    assert !Booking.exists?

    post(
      :create,
      booking: {
        group_id: group.id,
        occasion_id: occasion.id,
        student_count: 1,
        adult_count: 1,
        companion_name: "Foo",
        companion_email: "foo@example.com",
        companion_phone: "0311234567"
      }
    )

    booking = Booking.first

    assert               !booking.nil?
    assert_redirected_to booking_url(booking)
    assert_equal         "Platserna bokades.", flash[:notice]
    assert_equal         booking,              assigns(:booking)
    assert_equal         @user,                booking.user
    assert_equal         group,                booking.group
    assert_equal         group,                assigns(:group)
    assert_equal         occasion,             booking.occasion
    assert_equal         occasion,             assigns(:occasion)
    assert_nil           booking.answer_form
    assert_nil           NotificationRequest.where(id: notification_request.id).first
  end
  test "create with answer form" do
    occasion      = create(:occasion)
    group         = create(:group)
    questionnaire = create(:questionnaire, event: occasion.event)
    # Tickets to allow the booking validation to go through
    create_list(
      :ticket,
      10,
      booking: nil,
      group: group,
      district: group.school.district,
      occasion: occasion,
      event: occasion.event,
      state: :unbooked
    )

    post(
      :create,
      booking: {
        group_id: group.id,
        occasion_id: occasion.id,
        student_count: 1,
        adult_count: 1,
        companion_name: "Foo",
        companion_email: "foo@example.com",
        companion_phone: "0311234567"
      }
    )

    booking = Booking.first
    assert       !booking.answer_form.completed
    assert_equal occasion,      booking.answer_form.occasion
    assert_equal group,         booking.answer_form.group
    assert_equal questionnaire, booking.answer_form.questionnaire
  end

  test "edit" do
    booking = create(:booking, user: @user)

    get :edit, id: booking.id
    assert_response :success
    assert_template "bookings/new"
    assert          assigns(:is_edit)
    assert_equal    booking.group,    assigns(:group)
    assert_equal    booking.occasion, assigns(:occasion)
  end
  
  test "update with invalid booking" do
    booking = create(:booking, user: @user)

    put :update, id: booking.id, booking: { student_count: 100 }

    assert_response :success
    assert_template "bookings/new"
    assert          assigns(:is_edit)
    assert          !assigns(:booking).valid?
    assert_equal    booking,       assigns(:booking)
    assert_equal    booking.group, assigns(:group)
  end
  test "update with valid booking" do
    booking = create(:booking, user: @user, student_count: 2)

    put :update, id: booking.id, booking: { student_count: 1 }

    booking.reload

    assert_redirected_to booking_url(booking)
    assert_equal         1, booking.student_count
  end
  test "update with notifications, fully booked" do
    booking = create(:booking, user: @user, student_count: 30)

    notification_request = create(
      :notification_request,
      user: @user,
      event: booking.event,
      target_cd: NotificationRequest.targets.for_unbooking
    )

    assert booking.event.fully_booked?

    mailer_mock = stub(deliver: true)
    mailer_mock.expects(:deliver)
    NotificationRequestMailer.expects(:unbooking_notification).with(notification_request).returns(mailer_mock)

    put :update, id: booking.id, booking: { student_count: 10 }
    assert_redirected_to booking_url(booking)
  end
  test "update with notifications, too few tickets released" do
    APP_CONFIG.replace(unbooking_notification_request_seat_limit: 5)

    booking = create(:booking, user: @user, student_count: 30)

    # Passed occasion
    ts = Time.zone.now
    create(:occasion,
      event: booking.event,
      date: Date.yesterday,
      start_time: (ts - 23.hours).strftime("%H:%M"),
      stop_time: (ts - 22.hours).strftime("%H:%M"))

    notification_request = create(
      :notification_request,
      user: @user,
      event: booking.event,
      target_cd: NotificationRequest.targets.for_unbooking
    )

    assert booking.event.fully_booked?

    NotificationRequestMailer.expects(:unbooking_notification).never

    put :update, id: booking.id, booking: { student_count: 29 }
    assert_redirected_to booking_url(booking)
  end
  test "update with notifications, not fully booked" do
    booking = create(:booking, user: @user, student_count: 30)

    notification_request = create(
      :notification_request,
      user: @user,
      event: booking.event,
      target_cd: NotificationRequest.targets.for_unbooking
    )

    create(:occasion, event: booking.occasion.event)

    create_list(
      :ticket,
      10,
      booking: nil,
      group: booking.group,
      district: booking.group.school.district,
      occasion: booking.occasion,
      event: booking.occasion.event,
      state: :unbooked
    )

    assert !booking.event.fully_booked?(true)

    NotificationRequestMailer.expects(:unbooking_notification).never

    put :update, id: booking.id, booking: { student_count: 10 }
    assert_redirected_to booking_url(booking)
  end
  test "update with notifications, not fully booked but too few tickets" do
    APP_CONFIG.replace(unbooking_notification_request_seat_limit: 5)

    booking = create(:booking, user: @user, student_count: 30)

    # Passed occasion
    ts = Time.zone.now
    create(:occasion,
      event: booking.event,
      date: Date.yesterday,
      start_time: (ts - 23.hours).strftime("%H:%M"),
      stop_time: (ts - 22.hours).strftime("%H:%M"))

    notification_request = create(
      :notification_request,
      user: @user,
      event: booking.event,
      target_cd: NotificationRequest.targets.for_unbooking
    )

    create(:occasion, event: booking.occasion.event)

    create_list(
      :ticket,
      1,
      booking: nil,
      group: booking.group,
      district: booking.group.school.district,
      occasion: booking.occasion,
      event: booking.occasion.event,
      state: :unbooked
    )

    assert !booking.event.fully_booked?(true)

    mailer_mock = stub(deliver: true)
    mailer_mock.expects(:deliver)
    NotificationRequestMailer.expects(:unbooking_notification).with(notification_request).returns(mailer_mock)

    put :update, id: booking.id, booking: { student_count: 10 }
    assert_redirected_to booking_url(booking)
  end

  test "unbook" do
    booking = create(:booking, user: @user)

    get :unbook, id: booking
    
    assert_response :success
    assert_equal    Questionnaire.find_unbooking, assigns(:questionnaire)
    assert_equal(   {},                           assigns(:answer))
  end

  test "destroy" do
    booking = create(:booking, user: @user)

    # Passed occasion
    ts = Time.zone.now
    create(:occasion,
      event: booking.event,
      date: Date.yesterday,
      start_time: (ts - 23.hours).strftime("%H:%M"),
      stop_time: (ts - 22.hours).strftime("%H:%M"))

    notification_request = create(
      :notification_request,
      user: @user,
      event: booking.event,
      target_cd: NotificationRequest.targets.for_unbooking
    )

    mailer_mock = stub(deliver: true)
    mailer_mock.expects(:deliver).twice
    NotificationRequestMailer.expects(:unbooking_notification).with(notification_request).returns(mailer_mock)
    BookingMailer.expects(:booking_cancelled_email).with(
      [],
      @user,
      booking,
      nil
    ).returns(mailer_mock)

    delete :destroy, id: booking.id
    assert_redirected_to bookings_url()
    assert_equal         "Platserna avbokades.", flash[:notice]

    booking.reload

    assert booking.unbooked
    assert_equal @user, booking.unbooked_by
  end
  test "destroy, cancel" do
    booking = create(:booking, user: @user)

    delete :destroy, id: booking.id, commit: "Avbryt"

    assert_redirected_to booking_url(booking)
    assert_equal booking, Booking.find(booking.id)
  end
  test "destroy with questionnaire" do
    create(:user, roles: [roles(:admin)])

    booking                 = create(:booking, user: @user)
    questionnaire           = Questionnaire.find_unbooking
    questionnaire.questions = create_list(:question, 2, mandatory: true)

    # Missing answers
    delete :destroy, id: booking.id

    assert_response :success
    assert_template "bookings/unbook"

    assert       assigns(:answer_form).new_record?
    assert_equal booking.occasion, assigns(:occasion)
    assert_equal questionnaire,    assigns(:questionnaire)
    assert_equal({},               assigns(:answer))
    assert_equal booking,          assigns(:answer_form).booking
    assert_equal booking.occasion, assigns(:answer_form).occasion
    assert_equal booking.group,    assigns(:answer_form).group
    assert_equal questionnaire,    assigns(:answer_form).questionnaire

    # OK answers
    
    # Generate an answer hash: { question_id => "answer", question_id => "answer" ... }
    answer = Hash[questionnaire.questions.collect(&:id).zip(["foo"]*4)]

    delete :destroy, id: booking.id, answer: answer

    assert_redirected_to bookings_url()
    assert_equal         "Platserna avbokades.", flash[:notice]

    answer_form = AnswerForm.first
    assert       answer_form.completed
    assert_equal booking,               answer_form.booking
    assert_equal booking.occasion,      answer_form.occasion
    assert_equal booking.group,         answer_form.group
    assert_equal questionnaire,         answer_form.questionnaire
  end
end
