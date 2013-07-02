require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:check_roles).at_least_once.returns(true)

    @user = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "check roles, authed" do
    @controller.unstub(:authenticate)
    @controller.unstub(:check_roles)

    session[:current_user_id] = create(:user, :roles => [roles(:culture_worker)])

    get :options_list
    assert_response :success
  end
  test "check roles, unauthed" do
    @controller.unstub(:authenticate)
    @controller.unstub(:check_roles)

    session[:current_user_id] = create(:user, :roles => [roles(:booker)])

    get :options_list
    assert_redirected_to root_url()
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "show" do
    @controller.unstub(:authenticate)
    @controller.unstub(:check_roles)

    event = create(:event)
    category_groups = create_list(:category_group, 3)

    get :show, :id => event.id

    assert_response :success
    assert_equal    event,                           assigns(:event)
    assert_equal    category_groups.sort_by(&:name), assigns(:category_groups)
  end

  test "ticket allotment, no allotments" do
    event = create(:event)
    get :ticket_allotment, :id => event.id
    assert_redirected_to event
    assert_equal         "Evenemanget har ingen aktiv fördelning.", flash[:error]
  end
  test "ticket allotment, html" do
    allotment = create(:allotment)
    get :ticket_allotment, :id => allotment.event.id
    assert_response :success
    assert_equal    allotment.event, assigns(:event)
  end
  test "ticket allotment, csv for group" do
    group = create(:group)
    allotment = create(:allotment, :group => group, :district => group.school.district, :amount => 10)

    @controller.expects(:send_csv).with(
      "fordelning_evenemang#{allotment.event.id}.tsv",
      "Stadsdel\tSkola\tGrupp\tAntal biljetter\n#{group.school.district.name}\t#{group.school.name}\t#{group.name}\t10\n"
    ).returns(true)

    get :ticket_allotment, :id => allotment.event.id, :format => "xls"
  end
  test "ticket allotment, csv for district" do
    district = create(:district)
    allotment = create(:allotment, :group => nil, :district => district, :amount => 11)

    @controller.expects(:send_csv).with(
      "fordelning_evenemang#{allotment.event.id}.tsv",
      "Stadsdel\tSkola\tGrupp\tAntal biljetter\n#{district.name}\t\"\"\t\"\"\t11\n"
    ).returns(true)

    get :ticket_allotment, :id => allotment.event.id, :format => "xls"
  end
  test "ticket allotment, csv for all" do
    allotment = create(:allotment, :group => nil, :district => nil, :amount => 12)

    @controller.expects(:send_csv).with(
      "fordelning_evenemang#{allotment.event.id}.tsv",
      "Stadsdel\tSkola\tGrupp\tAntal biljetter\nHela staden\t\"\"\t\"\"\t12\n"
    ).returns(true)

    get :ticket_allotment, :id => allotment.event.id, :format => "xls"
  end

  test "new, admin" do
    category_groups   = create_list(:category_group,   2).sort_by(&:name)
    culture_providers = [
      create(:culture_provider, :name => "a", :map_address => "map address"),
      create(:culture_provider, :name => "b", :map_address => "dummy")
    ]

    # No culture provider
    get :new

    assert_response :success
    assert          assigns(:event).new_record?
    assert_nil      assigns(:event).culture_provider_id
    assert_nil      assigns(:event).map_address
    assert_equal    19,                assigns(:event).to_age
    assert_equal    category_groups,   assigns(:category_groups)
    assert_equal    culture_providers, assigns(:culture_providers)

    # Culture provider
    get :new, :culture_provider_id => culture_providers.first.id

    assert_response :success
    assert          assigns(:event).new_record?
    assert_equal    culture_providers.first.id, assigns(:event).culture_provider_id
    assert_equal    "map address",              assigns(:event).map_address
    assert_equal    19,                         assigns(:event).to_age
    assert_equal    category_groups,            assigns(:category_groups)
    assert_equal    culture_providers,          assigns(:culture_providers)
  end
  test "new, culture worker" do
    create(:culture_provider) # Not authed
    active = create(:culture_provider,   :active => true)
    inactive = create(:culture_provider, :active => false)

    user = create(:user, :roles => [roles(:culture_worker)])
    user.culture_providers << active
    user.culture_providers << inactive
    session[:current_user_id] = user.id

    get :new
    assert_equal [active], assigns(:culture_providers)
  end

  test "edit, authed" do
    category_groups = create_list(:category_group, 2).sort_by(&:name)
    event           = create(:event)

    get :edit, :id => event.id
    assert_response :success
    assert_template "events/new"
    assert_equal    event,           assigns(:event)
    assert_equal    category_groups, assigns(:category_groups)
  end
  test "edit, unauthed" do
    category_groups           = create_list(:category_group, 2).sort_by(&:name)
    event                     = create(:event)
    user                      = create(:user, :roles => [roles(:culture_worker)])
    session[:current_user_id] = user.id

    get :edit, :id => event.id
    assert_redirected_to event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "create, admin" do
    categories       = create_list(:category, 2)
    category_groups  = categories.collect(&:category_group).sort_by(&:name)
    culture_provider = create(:culture_provider)

    # Invalid
    culture_providers = [ create_list(:culture_provider, 2), culture_provider ].flatten.sort_by(&:name)
    post :create, :event => { :culture_provider_id => culture_provider.id }
    assert_response :success
    assert_template "events/new"
    assert_equal    category_groups,   assigns(:category_groups)
    assert_equal    culture_providers, assigns(:culture_providers)

    # Valid
    post(
      :create,
      :event => {
        :name => "Event",
        :description => "Foo",
        :from_age => 10,
        :to_age => 11,
        :visible_from => Date.today - 1,
        :visible_to => Date.today + 1,
        :culture_provider_id => culture_provider.id
      },
      :category_ids => [ categories.first.id, "-1" ]
    )

    event = Event.last
    assert_redirected_to event
    assert_equal         "Evenemanget skapades.", flash[:notice]
    assert_equal         [categories.first], event.categories
  end
  test "create, culture worker" do
    categories       = create_list(:category, 2)
    category_groups  = categories.collect(&:category_group).sort_by(&:name)

    create(:culture_provider) # Not authed
    active   = create(:culture_provider, :active => true)
    inactive = create(:culture_provider, :active => false)

    user = create(:user, :roles => [roles(:culture_worker)])
    user.culture_providers << active
    user.culture_providers << inactive
    session[:current_user_id] = user.id

    # Invalid
    post :create, :event => { :culture_provider_id => active.id }
    assert_response :success
    assert_template "events/new"
    assert_equal    category_groups, assigns(:category_groups)
    assert_equal    [active],        assigns(:culture_providers)

    # Valid
    post(
      :create,
      :event => {
        :name => "Event",
        :description => "Foo",
        :from_age => 10,
        :to_age => 11,
        :visible_from => Date.today - 1,
        :visible_to => Date.today + 1,
        :culture_provider_id => active.id
      },
      :category_ids => [ categories.first.id, "-1" ]
    )

    event = Event.last
    assert_redirected_to event
    assert_equal         "Evenemanget skapades.", flash[:notice]
    assert_equal         [categories.first], event.categories
  end
  test "create, unauthed" do
    user                      = create(:user, :roles => [roles(:culture_worker)])
    session[:current_user_id] = user.id

    post :create, :event => {}
    assert_redirected_to root_url()
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "update, unauthed" do
    event                     = create(:event)
    user                      = create(:user, :roles => [roles(:culture_worker)])
    session[:current_user_id] = user.id

    put :update, :id => event.id
    assert_redirected_to event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end
  test "update, authed" do
    categories      = create_list(:category, 2)
    category_groups = categories.collect(&:category_group).sort_by(&:name)
    event           = create(:event, :name => "foo")
    
    # Invalid
    put :update, :id => event.id, :event => { :name => "" }
    assert_response :success
    assert_template "events/new"
    assert_equal    event, assigns(:event)
    assert          !assigns(:event).valid?
    assert_equal    category_groups, assigns(:category_groups)

    # Valid
    put :update, :id => event.id, :event => { :name => "bar" }, :category_ids => [categories.last.id, "-1"]
    assert_redirected_to event
    assert_equal         "Evenemanget uppdaterades.", flash[:notice]

    event.reload
    assert_equal "bar",             event.name
    assert_equal [categories.last], event.categories
  end

  test "destroy, unauthed" do
    event                     = create(:event)
    user                      = create(:user, :roles => [roles(:culture_worker)])
    session[:current_user_id] = user.id

    delete :destroy, :id => event.id
    assert_redirected_to event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
    assert               Event.find(event.id)
  end
  test "destroy, authed" do
    event         = create(:event)
    questionnaire = create(:questionnaire, :event => event)

    delete :destroy, :id => event.id
    assert_redirected_to root_url()
    assert_equal         "Evenemanget raderades.", flash[:notice]
    assert_nil           Event.first(:conditions => { :id => event.id })
    assert_nil           Questionnaire.first(:conditions => { :id => questionnaire.id })
  end

  test "options list" do
    events = create_list(:event, 2).sort_by(&:name)

    get :options_list
    assert_response :success
    assert_template "events/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    events, assigns(:events)

    get :options_list, :culture_provider_id => events.first.culture_provider.id
    assert_response :success
    assert_template "events/options_list"
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
    assert_equal    [events.first], assigns(:events)
  end

  test "options list, errors" do
    Event.stubs(:find).raises
    get :options_list
    assert_response 404
    assert          @response.headers["Content-Type"] =~ /\btext\/plain\b/
  end
end
