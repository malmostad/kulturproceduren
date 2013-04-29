require 'test_helper'

class OccasionsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)

    @user = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "require culture worker" do
    user = create(:user, :roles => [roles(:culture_worker)])
    session[:current_user_id] = user.id

    occasion = create(:occasion)

    get :edit, :id => occasion.id
    assert_redirected_to occasion.event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
    get :update, :id => occasion.id
    assert_redirected_to occasion.event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
    delete :destroy, :id => occasion.id
    assert_redirected_to occasion.event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
    get :cancel, :id => occasion.id
    assert_redirected_to occasion.event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "show" do
    @controller.unstub(:authenticate)

    occasion = create(:occasion)
    category_groups = create_list(:category_group, 3).sort_by(&:name)

    get :show, :id => occasion.id
    assert_response :success
    assert_template "events/show"
    assert_equal    occasion,        assigns(:selected_occasion)
    assert_equal    occasion.event,  assigns(:event)
    assert_equal    category_groups, assigns(:category_groups)
  end

  test "edit" do
    occasion = create(:occasion)
    category_groups = create_list(:category_group, 3).sort_by(&:name)

    get :edit, :id => occasion.id
    assert_response :success
    assert_template "events/show"
    assert_equal    occasion,        assigns(:occasion)
    assert_equal    occasion.event,  assigns(:event)
    assert_equal    category_groups, assigns(:category_groups)
  end

  test "create, unauthed" do
    user  = create(:user, :roles => [roles(:culture_worker)])
    event = create(:event)
    session[:current_user_id] = user.id

    post :create, :occasion => { :event_id => event.id }
    assert_redirected_to event
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
  end
  test "create" do
    event           = create(:event)
    category_groups = create_list(:category_group, 3).sort_by(&:name)

    # Invalid
    post :create, :occasion => { :event_id => event.id }
    assert_response :success
    assert_template "events/show"
    assert          assigns(:occasion).new_record?
    assert          !assigns(:occasion).valid?
    assert_equal    event, assigns(:event)
    assert_equal    category_groups, assigns(:category_groups)

    # Valid
    occasion_data = { :event_id => event.id, :date => Date.today, :address => "Address", :seats => 10 }
    post :create, :occasion => occasion_data
    assert_redirected_to event
    assert_equal         "Föreställningen skapades.",  flash[:notice]
    assert_equal         occasion_data.stringify_keys, session[:last_occasion_added]
    
    occasion = Occasion.last
    assert_equal event,      occasion.event
    assert_equal Date.today, occasion.date
  end

  test "update" do
    occasion        = create(:occasion, :seats => 10)
    category_groups = create_list(:category_group, 3).sort_by(&:name)

    # Invalid
    put :update, :id => occasion.id, :occasion => { :seats => nil }
    assert_response :success
    assert_template "events/show"
    assert          !assigns(:occasion).valid?
    assert_equal    occasion.event, assigns(:event)
    assert_equal    occasion, assigns(:occasion)
    assert_equal    category_groups, assigns(:category_groups)

    # Valid
    put :update, :id => occasion.id, :occasion => { :seats => 11 }
    assert_redirected_to occasion.event
    assert_equal         "Föreställningen uppdaterades.",  flash[:notice]
    assert_equal         11, occasion.reload.seats
  end

  test "destroy" do
    occasion = create(:occasion)

    delete :destroy, :id => occasion.id
    assert_redirected_to occasion.event
    assert_equal         "Föreställningen togs bort.", flash[:notice]
    assert_nil           Occasion.first(:conditions => { :id => occasion.id })
  end

  test "cancel" do
    occasion = create(:occasion, :cancelled => false)
    OccasionMailer.expects(:deliver_occasion_cancelled_email).with(occasion)

    get :cancel, :id => occasion.id
    assert_redirected_to occasion
    assert_equal         "Föreställningen ställdes in.", flash[:notice]
    assert               occasion.reload.cancelled
  end

  test "ticket availability, alloted group" do
    group    = create(:group)
    event    = create(:event, :ticket_state => :alloted_group)
    occasion = create(:occasion, :event => event)
    create(:allotment, :event => event, :group => group, :district => group.school.district, :amount => 1)
    create(:group) # dummy

    get :ticket_availability, :id => occasion.id
    assert_equal occasion, assigns(:occasion)
    assert_equal [group.school], assigns(:entities)

    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :ticket_availability, :id => occasion.id
    assert_template "occasions/_ticket_availability_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    occasion, assigns(:occasion)
    assert_equal    [group.school], assigns(:entities)
  end
  test "ticket availability, alloted district" do
    group    = create(:group)
    event    = create(:event, :ticket_state => :alloted_district)
    occasion = create(:occasion, :event => event)
    create(:allotment, :event => event, :group => group, :district => group.school.district, :amount => 1)
    create(:group) # dummy

    get :ticket_availability, :id => occasion.id
    assert_equal occasion, assigns(:occasion)
    assert_equal [group.school.district], assigns(:entities)

    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :ticket_availability, :id => occasion.id
    assert_template "occasions/_ticket_availability_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    occasion, assigns(:occasion)
    assert_equal    [group.school.district], assigns(:entities)
  end
  test "ticket availability, free for all" do
    event    = create(:event, :ticket_state => :free_for_all)
    occasion = create(:occasion, :event => event)
    create(:allotment, :amount => 1)

    get :ticket_availability, :id => occasion.id
    assert_equal occasion, assigns(:occasion)
    assert_nil   assigns(:entities)

    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :ticket_availability, :id => occasion.id
    assert_template "occasions/_ticket_availability_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    occasion, assigns(:occasion)
    assert_nil      assigns(:entities)
  end
  test "ticket availability, wrong state" do
    event    = create(:event, :ticket_state => nil)
    occasion = create(:occasion, :event => event)

    get :ticket_availability, :id => occasion.id
    assert_redirected_to root_url()
    assert_equal         "Platstillgänglighet kan inte presenteras för den önskade föreställningen.", flash[:error]

    @request.env["HTTP_X_REQUESTED_WITH"] = "xmlhttprequest"
    get :ticket_availability, :id => occasion.id
    assert_response 404
    assert          @response.body.blank?
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
  end
end
