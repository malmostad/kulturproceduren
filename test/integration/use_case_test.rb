require_relative '../test_helper'


class UseCaseTest < ActionDispatch::IntegrationTest

  setup do
    @ar_log_level = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = 1

    admin_role  = Role.find_by_name('admin')
    cw_role     = Role.find_by_name('culture_worker')
    booker_role = Role.find_by_name('booker')

    @culture_provider = create(:culture_provider)
    
    @booker_user    = create(:user, username: 'booker',         roles: [booker_role])
    @admin_user     = create(:user, username: 'admin',          roles: [admin_role])
    @culture_worker = create(:user, username: 'culture_worker', roles: [cw_role])
    @culture_worker.culture_providers << @culture_provider
    
    @category = create(:category)
    @district = create(:district_with_age_groups, school_count: 1, group_count: 1)

    @group = Group.last
  end


  teardown do
    ActiveRecord::Base.logger.level = @ar_log_level
  end


  test "use case" do    

    # Culture worker logs in
    cv_session = login('culture_worker')

    # Culture worker selects a culture provider
    cv_session.browse('/culture_providers')
    cv_session.browse("/culture_providers/#{@culture_provider.id}")

    # Culture worker creates an event with an occasion
    cv_session.browse('/events/new', culture_provider_id: @culture_provider.id)
    event_id = cv_session.create_event([@category.id.to_s], attributes_for(:event, culture_provider_id: @culture_provider.id))
    
    cv_session.browse("/events/#{event_id}")
    occasion_id = cv_session.create_occasion(attributes_for(:occasion, event_id: event_id))

    # Administrator logs in and views the event
    admin_session = login('admin')
    admin_session.browse("/events/#{event_id}")
    
    # Administrator distributes the tickets
    admin_session.distribute_tickets(event_id)
    admin_session.browse("/events/#{event_id}/ticket_allotment")

    # Booker logs in 
    booker_session = login('booker')
    booker_session.browse("/events/#{event_id}")
    booker_session.browse("/occasions/#{occasion_id}/bookings/new")
    booker_session.book(occasion_id)
  end


  private


  module CustomDsl

    def browse(path, params = {})
      get path, params
      assert_response :success
    end


    def create_event(category_ids, attributes)
      assert_difference('Event.count', 1) do
        post('/events', category_ids: category_ids, event: attributes)
      end
      Event.last.id
    end


    def create_occasion(attributes)
      assert_difference('Occasion.count') do
        post('/occasions', occasion: attributes)
      end
      Occasion.last.id
    end


    def distribute_tickets(event_id)
      browse("/allotment/init/#{event_id}")
      post("/allotment/assign_params/#{event_id}", id: event_id, allotment: {
        "release_date"=>1.days.ago.strftime("%Y-%m-%d"),
        "district_transition_date"=>"2014-03-27",
        "free_for_all_transition_date"=>"2014-04-10",
        "num_tickets"=>"100",
        "ticket_state"=>"1",
        "district_ids"=>[@district.id]
      })
      browse("/allotment/distribute/#{event_id}")
      post("/allotment/create_tickets/#{event_id}", id: event_id, create_tickets: 1, allotment:{
        ticket_assignment: {@group.id => '21'}
      })
    end


    def book(occasion_id)
      attributes = {
        student_count:    10,
        adult_count:      1,
        wheelchair_count: '',
        companion_name:   'John Smith',
        companion_email:  'jsmith@example.com',
        companion_phone:  '070-0000000',
        requirement:      '',
        group_id:         @group.id,
        occasion_id:      occasion_id
      }
      assert_difference('Booking.count') do
        post('/bookings', booking: attributes)
      end
      Booking.last.id
    end

  end


  def login(username)
    open_session do |session|
      session.extend(CustomDsl)
      user = User.find_by_username(username)
      session.post '/login/login', user: {username: user.username, password: 'password'}
      session.assert_redirected_to '/'
    end
  end


end