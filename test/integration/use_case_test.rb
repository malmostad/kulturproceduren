require_relative '../test_helper'
require_relative 'use_case_test_helper'


class UseCaseTest < ActionDispatch::IntegrationTest

  include UseCaseTestHelper

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

    # Administrator creates a questionnaire
    questionnaire_id = admin.create_questionnaire(event_id)
    question_id      = admin.create_question(questionnaire_id)

    Timecop.freeze(TICKET_RELEASE_DATE)

    # Booker logs in and books
    booker = login('booker')
    booker.browse("/events/#{event_id}")
    booker.browse("/occasions/#{occasion_id}/bookings/new")
    booking_id = booker.book(occasion_id)

    # Notification to booker
    Timecop.freeze(Time.parse(OCCASION_DATE) - 2.days)

    occasion_mailer = stub(:deliver => true)
    OccasionMailer.expects(:reminder_email).once.returns(occasion_mailer)
    NotifyOccasionReminder.new(Date.today, 2).run

    # Occasion day, send questionnaire link to companions 
    Timecop.freeze(OCCASION_DATE)
    OccasionMailer.expects(:answer_form_email).once.returns(occasion_mailer)
    SendAnswerForms.new(Date.today, 0).run

    # Send reminder about questionnaire
    Timecop.freeze(Time.parse(OCCASION_DATE) + 2.days)
    OccasionMailer.expects(:answer_form_reminder_email).once.returns(occasion_mailer)
    RemindAnswerForm.new(Date.today, 2).run

    # Companion answers questionnaire
    answer_questionnaire(booking_id)

    # Host reports attendance
    host = login('host')
    host.report_attendance(occasion_id)

  end  

end