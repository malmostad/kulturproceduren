require 'test_helper'

class NotificationRequestsControllerTest < ActionController::TestCase
  def setup
    @user = create(:user, :roles => [roles(:booker)])
    session[:current_user_id] = @user.id
  end

  test "require booker" do
    event = create(:event)
    session[:current_user_id] = create(:user, :roles =>[]).id

    get :new, :event_id => event.id
    assert_redirected_to root_url()
    assert_equal         "Du har inte behörighet att boka platser", flash[:error]

    post :create, :event_id => event.id
    assert_redirected_to root_url()
    assert_equal         "Du har inte behörighet att boka platser", flash[:error]
  end

  test "load event" do
    get :new, :event_id => -1
    assert_redirected_to root_url()
    assert_equal         "Kunde inte hitta angivet evenemang", flash[:error]

    post :create, :event_id => -1
    assert_redirected_to root_url()
    assert_equal         "Kunde inte hitta angivet evenemang", flash[:error]
  end

  test "new, for group alloted event" do
    event = create(:event, :ticket_state => Event::ALLOTED_GROUP)
    group = create(:group)
    session[:group_selection] = {
      :group_id    => group.id,
      :school_id   => group.school.id,
      :district_id => group.school.district.id
    }

    get :new, :event_id => event.id
    assert_response :success
    assert_equal    event, assigns(:event)
    assert          assigns(:notification_request).new_record?
    assert_equal    event, assigns(:notification_request).event
    assert_equal    group, assigns(:notification_request).group
  end
  test "new, for district alloted event" do
    event = create(:event, :ticket_state => Event::ALLOTED_DISTRICT)
    group = create(:group)
    session[:group_selection] = {
      :group_id    => group.id,
      :school_id   => group.school.id,
      :district_id => group.school.district.id
    }

    get :new, :event_id => event.id
    assert_response :success
    assert_equal    event, assigns(:event)
    assert          assigns(:notification_request).new_record?
    assert_equal    event, assigns(:notification_request).event
    assert_equal    group, assigns(:notification_request).group
  end
  test "new, for free for all event" do
    event = create(:event, :ticket_state => Event::FREE_FOR_ALL)

    get :new, :event_id => event.id
    assert_response :success
    assert_equal    event, assigns(:event)
    assert          assigns(:notification_request).new_record?
    assert_equal    event, assigns(:notification_request).event
    assert_nil      assigns(:notification_request).group

    notification_request = create(:notification_request, :user => @user, :event => event, :target_cd => NotificationRequest.targets.for_unbooking)

    get :new, :event_id => event.id
    assert_redirected_to event
    assert_equal         "Du är redan registrerad för restplatser på detta evenemang", flash[:warning]
  end
  test "new, for event without tickets" do
    event = create(:event, :ticket_state => nil)

    get :new, :event_id => event.id
    assert_redirected_to event
    assert_equal         "Evenemanget är inte bokningsbart.", flash[:warning]
  end

  test "create, cancel" do
    event = create(:event)
    assert !NotificationRequest.exists?
    post :create, :event_id => event.id, :cancel => true
    assert_redirected_to event
    assert !NotificationRequest.exists?
  end
  test "create, alloted" do
    event = create(:event, :ticket_state => Event::ALLOTED_GROUP)

    post :create, :event_id => event.id, :notification_request => {}
    assert_redirected_to event
    assert_equal         "Du är nu registrerad att få meddelanden när platser på detta evenemang blir tillgängliga för din klass/avdelning.", flash[:notice]

    notification_request = NotificationRequest.last
    assert_equal event, notification_request.event
    assert_equal @user, notification_request.user
    assert       notification_request.for_transition?
  end
  test "create, free for all" do
    event = create(:event, :ticket_state => Event::FREE_FOR_ALL)

    post :create, :event_id => event.id, :notification_request => {}
    assert_redirected_to event
    assert_equal         "Du är nu registrerad att få meddelanden om restplatser på detta evenemang blir tillgängliga.", flash[:notice]

    notification_request = NotificationRequest.last
    assert_equal event, notification_request.event
    assert_equal @user, notification_request.user
    assert       notification_request.for_unbooking?
  end
end
