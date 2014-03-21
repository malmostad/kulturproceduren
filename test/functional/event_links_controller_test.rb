# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class EventLinksControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)

    @user = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @user.id

    @culture_provider = create(:culture_provider)
    @event            = create(:event, :culture_provider => @culture_provider)

    create_list(:event, 4, :culture_provider => @culture_provider)
  end

  test "load entity, authed" do
    get :index, :culture_provider_id => @culture_provider.id
    assert_response :success
    assert_equal    @culture_provider, assigns(:culture_provider)

    get :index, :event_id => @event.id
    assert_response :success
    assert_equal    @event, assigns(:event)
  end
  test "load entity, not authed" do
    session[:current_user_id] = create(:user, :roles => [roles(:culture_worker)]).id

    get :index, :culture_provider_id => @culture_provider.id
    assert_redirected_to @culture_provider
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]

    get :index, :event_id => @event.id
    assert_redirected_to @event
    assert_equal         "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "new" do
    session[:event_links] = nil

    @event.linked_events            << @event
    @culture_provider.linked_events << @event

    # No selected culture provider
    get :new, :culture_provider_id => @culture_provider.id

    assert_response :success
    assert_equal(   {}, session[:event_links])
    assert_equal    CultureProvider.order("name"), assigns(:culture_providers)
    assert_nil      assigns(:events)

    # Culture provider
    session[:event_links][:selected_culture_provider] = @culture_provider.id
    get :new, :culture_provider_id => @culture_provider.id

    assert_response :success
    assert_equal    CultureProvider.order("name"),                        assigns(:culture_providers)
    assert_equal    @culture_provider,                                    assigns(:selected_culture_provider)
    assert_equal    Event.where("id != ?", @event.id).order("name").to_a, assigns(:events)

    # Event
    session[:event_links][:selected_culture_provider] = @culture_provider.id
    get :new, :event_id => @event.id

    assert_response :success
    assert_equal    CultureProvider.order("name"),                        assigns(:culture_providers)
    assert_equal    @culture_provider,                                    assigns(:selected_culture_provider)
    assert_equal    Event.where("id != ?", @event.id).order("name").to_a, assigns(:events)
  end

  test "select culture provider, for culture provider" do
    session[:event_links] = nil
    get :select_culture_provider, :culture_provider_id => @culture_provider.id, :selected_culture_provider_id => @culture_provider.id
    assert_redirected_to new_culture_provider_event_link_url(:culture_provider_id => @culture_provider.id)
    assert_equal         @culture_provider.id, session[:event_links][:selected_culture_provider]
  end
  test "select culture provider, for event" do
    session[:event_links] = nil
    get :select_culture_provider, :event_id => @event.id, :selected_culture_provider_id => @culture_provider.id
    assert_redirected_to new_event_event_link_url(:event_id => @event.id)
    assert_equal         @culture_provider.id, session[:event_links][:selected_culture_provider]
  end

  test "select event, for event" do
    assert @event.linked_events.blank?
    get :select_event, :id => @event.id, :event_id => @event.id
    assert_redirected_to event_event_links_url(:event_id => @event.id)
    assert_equal         "Länken mellan evenemangen skapades.", flash[:notice]
    assert               @event.linked_events(true).include?(@event)
  end
  test "select event, for culture provider" do
    assert @culture_provider.linked_events.blank?
    get :select_event, :id => @event.id, :culture_provider_id => @culture_provider.id
    assert_redirected_to culture_provider_event_links_url(:culture_provider_id => @culture_provider.id)
    assert_equal         "Länken mellan evenemanget och arrangören skapades.", flash[:notice]
    assert               @culture_provider.linked_events(true).include?(@event)
  end

  test "destroy, for event" do
    @event.linked_events << @event
    delete :destroy, :id => @event.id, :event_id => @event.id
    assert_redirected_to event_event_links_url(:event_id => @event.id)
    assert_equal         "Länken mellan evenemangen togs bort.", flash[:notice]
    assert               @event.linked_events(true).blank?
  end
  test "destroy, for culture provider" do
    @culture_provider.linked_events << @event
    delete :destroy, :id => @event.id, :culture_provider_id => @culture_provider.id
    assert_redirected_to culture_provider_event_links_url(:culture_provider_id => @culture_provider.id)
    assert_equal         "Länken mellan evenemanget och arrangören togs bort.", flash[:notice]
    assert               @culture_provider.linked_events(true).blank?
  end
end
