require_relative '../test_helper'

class CultureProviderLinksControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)

    @user = create(:user, roles: [roles(:admin)])
    session[:current_user_id] = @user.id

    @culture_providers        = create_list(:culture_provider, 2)
    @culture_provider         = @culture_providers.first
    @event                    = create(:event, culture_provider: @culture_provider)
  end

  test "load entity, authorized" do
    user  = create(:user,  roles: [roles(:culture_worker)], culture_providers: [@culture_providers.first])
    event = create(:event, culture_provider: @culture_providers.first)
    session[:current_user_id] = user.id

    get :index, culture_provider_id: @culture_providers.first.id
    assert_response :success
    assert_equal    @culture_providers.first, assigns(:culture_provider)

    get :index, event_id: event.id
    assert_response :success
    assert_equal    event, assigns(:event)
  end
  test "load entity, unauthorized" do
    user  = create(:user,  roles: [roles(:culture_worker)], culture_providers: [@culture_providers.second])
    event = create(:event, culture_provider: @culture_providers.first)
    session[:current_user_id] = user.id

    get :index, culture_provider_id: @culture_providers.first.id
    assert_redirected_to @culture_providers.first
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]

    get :index, event_id: event.id
    assert_redirected_to event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "index" do
    get :index, culture_provider_id: @culture_provider
    assert_response :success
    assert_equal CultureProvider.not_linked_to_culture_provider(@culture_provider).order("name asc").to_a, assigns(:culture_providers)
    get :index, event_id: @event.id
    assert_response :success
    assert_equal CultureProvider.not_linked_to_event(@event).order("name asc").to_a, assigns(:culture_providers)
  end

  test "select, culture provider" do
    assert @culture_providers.first.linked_culture_providers.blank?
    assert @culture_providers.second.linked_culture_providers.blank?

    get :select, id: @culture_providers.second.id, culture_provider_id: @culture_provider.id
    assert_redirected_to culture_provider_culture_provider_links_url(culture_provider_id: @culture_provider.id)
    assert_equal         "Länken mellan arrangörerna skapades.", flash[:notice]
    
    assert @culture_providers.first.linked_culture_providers(true).include?(@culture_providers.second)
    assert @culture_providers.second.linked_culture_providers(true).include?(@culture_providers.first)
  end
  test "select, event" do
    assert @event.linked_culture_providers.blank?

    get :select, id: @culture_providers.second.id, event_id: @event.id
    assert_redirected_to event_culture_provider_links_url(event_id: @event.id)
    assert_equal         "Länken mellan arrangören och evenemanget skapades.", flash[:notice]
    
    assert @event.linked_culture_providers(true).include?(@culture_providers.second)
  end

  test "destroy, culture provider" do
    @culture_providers.first.linked_culture_providers << @culture_providers.second
    @culture_providers.second.linked_culture_providers << @culture_providers.first

    get :destroy, id: @culture_providers.first.id, culture_provider_id: @culture_providers.second.id
    assert_redirected_to culture_provider_culture_provider_links_url(culture_provider_id: @culture_providers.second.id)
    assert_equal         "Länken mellan arrangörerna togs bort.", flash[:notice]
    assert               @culture_providers.first.linked_culture_providers(true).blank?
    assert               @culture_providers.second.linked_culture_providers(true).blank?
  end
  test "destroy, event" do
    @event.linked_culture_providers << @culture_providers.second

    get :destroy, id: @culture_providers.second.id, event_id: @event.id
    assert_redirected_to event_culture_provider_links_url(event_id: @event.id)
    assert_equal         "Länken mellan arrangören och evenemanget togs bort.", flash[:notice]
    assert               @event.linked_culture_providers(true).blank?
  end
end
