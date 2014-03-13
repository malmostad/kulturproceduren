module UseCaseTestHelper

  EVENT_VISIBLE_FROM           = "1970-01-05" # Monday
  TICKET_RELEASE_DATE          = "1970-01-06" # Tuesday
  DISTRICT_TRANSITION_DATE     = "1970-01-10" # Sunday
  FREE_FOR_ALL_TRANSITION_DATE = "1970-01-14" # Wednesday
  EVENT_VISIBLE_TO             = "1970-01-15" # Thursday
  OCCASION_DATE                = "1970-01-16" # Friday


  def login(username)
    open_session do |session|
      session.extend(UseCaseTestHelper::SessionDsl)
      user = User.find_by_username(username)
      session.post '/login/login', user: {username: user.username, password: 'password'}
      session.assert_redirected_to '/'
    end
  end

  def answer_questionnaire(booking_id)
    answer_form_id = Booking.find(booking_id).answer_form.id
    get "/questionnaires/#{answer_form_id}/answer"
    assert_response :success

    question_id = Question.last.id
    assert_difference('Answer.count', 1) do
      post "/questionnaires/#{answer_form_id}/answer", answer: {question_id => "hej"}
    end
    assert_match /Tack för att du svarade/, flash[:notice]
  end


  #
  #
  #

  def setup_data
    admin_role  = Role.find_by_name('admin')
    cw_role     = Role.find_by_name('culture_worker')
    booker_role = Role.find_by_name('booker')
    host_role   = Role.find_by_name('host')

    @culture_provider = create(:culture_provider)

    @host           = create(:user, username: 'host',           roles: [host_role])
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




  module SessionDsl

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
  
  
    def create_questionnaire(event_id)
      browse('/questionnaires')
      browse('/questionnaires/new')
      attributes = {event_id: event_id, description: "The quick brown fox..."}
      assert_difference('Questionnaire.count', 1) do
        post('/questionnaires', questionnaire: attributes)
      end
      questionnaire_id = Questionnaire.last.id
      assert_redirected_to "/questionnaires/#{questionnaire_id}"
      browse("/questionnaires/#{questionnaire_id}")
      questionnaire_id
    end
  
  
    def create_question(questionnaire_id)
      attributes = {
        qtype:      'QuestionText',
        question:   'How much is a boat?',
        choice_csv: '',
        mandatory:  '1',
        template:   'false'
      }
      assert_difference('Question.count', 1) do
        post("/questionnaires/#{questionnaire_id}/questions", questionnaire_id: questionnaire_id, question: attributes)
      end
      assert_redirected_to("/questionnaires/#{questionnaire_id}")
      browse("/questionnaires/#{questionnaire_id}")
      Question.last.id
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

    # Started POST "/occasions/3/attendance/update_report" for 127.0.0.1 at 2014-03-13 08:46:10 +0000
    # Processing by AttendanceController#update_report as HTML
    #   Parameters: {"utf8"=>"✓", "authenticity_token"=>"iClf6+1rI5yZWG62WuN3vuX06Jt72ASt5EvvG6nXpuk=", "attendance"=>{"3"=>{"254"=>{"normal"=>"9", "adult"=>"1", "wheelchair"=>"0"}}}, "commit"=>"Rapportera närvaro", "occasion_id"=>"3"}
    # Redirected to http://localhost:3000/occasions/3/attendance/report
    # Completed 302 Found in 26.4ms (ActiveRecord: 9.7ms)
    # 
    # 
    # Started GET "/occasions/3/attendance/report" for 127.0.0.1 at 2014-03-13 08:46:10 +0000
    # Processing by AttendanceController#report as HTML
    #   Parameters: {"occasion_id"=>"3"}
    #   Rendered attendance/report.html.erb within layouts/standard (9.4ms)
    #   Rendered shared/_head.html.erb (3.8ms)
    # Completed 200 OK in 21.0ms (Views: 14.5ms | ActiveRecord: 4.2ms)



    def report_attendance(occasion_id)
      browse("/occasions/#{occasion_id}/attendance/report")
      post("/occasions/#{occasion_id}/attendance/update_report", occasion_id: occasion_id, attendance: {
        occasion_id.to_s => {@group.id.to_s => {
          normal: 10,
          adult:  1,
          wheelchair: 0
        }}
      })
      assert_redirected_to "/occasions/#{occasion_id}/attendance/report"
      assert_match /Närvaron uppdaterades/, flash[:notice]
    end

  end

end