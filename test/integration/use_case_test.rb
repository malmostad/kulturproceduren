require_relative '../test_helper'


class UseCaseTest < ActionDispatch::IntegrationTest

  EVENT_VISIBLE_FROM           = "1970-01-05" # Monday
  TICKET_RELEASE_DATE          = "1970-01-06" # Tuesday
  DISTRICT_TRANSITION_DATE     = "1970-01-10" # Sunday
  FREE_FOR_ALL_TRANSITION_DATE = "1970-01-14" # Wednesday
  EVENT_VISIBLE_TO             = "1970-01-15" # Thursday
  OCCASION_DATE                = "1970-01-16" # Friday
  

  setup do
    setup_time
    setup_data
    setup_ar_logging
  end


  teardown do
    teardown_ar_logging
    teardown_time
  end


  test "use case" do
    

    # Culture worker logs in
    culture_worker = login('culture_worker')

    # Culture worker selects a culture provider
    culture_worker.browse('/culture_providers')
    culture_worker.browse("/culture_providers/#{@culture_provider.id}")

    # Culture worker creates an event with an occasion
    culture_worker.browse('/events/new', culture_provider_id: @culture_provider.id)
    event_id = culture_worker.create_event
    culture_worker.browse("/events/#{event_id}")
    occasion_id = culture_worker.create_occasion(event_id)

    # Administrator logs in, views the event, and distributes tickets
    admin = login('admin')
    admin.browse("/events/#{event_id}")
    admin.distribute_tickets(event_id)
    admin.browse("/events/#{event_id}/ticket_allotment")

    Timecop.freeze(TICKET_RELEASE_DATE)

    # Booker logs in and books
    booker = login('booker')
    booker.browse("/events/#{event_id}")
    booker.browse("/occasions/#{occasion_id}/bookings/new")
    booker.book(occasion_id)

    # Notification to booker
    Timecop.freeze(Time.parse(OCCASION_DATE) - 2.days)
    
    occasion_mailer = stub(:deliver => true)
    OccasionMailer.expects(:reminder_email).once.returns(occasion_mailer)
    NotifyOccasionReminder.new(Date.today, 2).run

  end






  private


  module CustomDsl

    def browse(path, params = {})
      get path, params
      assert_response :success
    end


    def create_event
      assert_difference('Event.count', 1) do
        attributes = attributes_for(:event,
          culture_provider_id: @culture_provider.id,
          visible_from:        EVENT_VISIBLE_FROM,
          visible_to:          EVENT_VISIBLE_TO
        )
        post('/events', category_ids: [@category.id], event: attributes)
      end
      Event.last.id
    end


    def create_occasion(event_id)
      assert_difference('Occasion.count') do
        attributes = attributes_for(:occasion, event_id: event_id, date: OCCASION_DATE)
        post('/occasions', occasion: attributes)
      end
      Occasion.last.id
    end


    def distribute_tickets(event_id)
      browse("/allotment/init/#{event_id}")
      post("/allotment/assign_params/#{event_id}", id: event_id, allotment: {
        release_date:                 TICKET_RELEASE_DATE,
        district_transition_date:     DISTRICT_TRANSITION_DATE,
        free_for_all_transition_date: FREE_FOR_ALL_TRANSITION_DATE,
        num_tickets:                  100,
        ticket_state:                 1,
        district_ids:                 [@district.id]
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

  #
  #
  #

  def setup_data
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

  def setup_ar_logging
    @ar_log_level = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = 1
  end

  def setup_time
    Timecop.freeze(Time.at(0))
  end


  #
  #
  #

  def teardown_ar_logging
    ActiveRecord::Base.logger.level = @ar_log_level
  end

  def teardown_time
    Timecop.return
  end

end