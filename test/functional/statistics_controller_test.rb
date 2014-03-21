# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class StatisticsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  test "index" do
    # Included terms
    create(:occasion, :date => "2009-08-01") # ht2009
    create(:occasion, :date => "2010-04-01") # vt2010
    create(:occasion, :date => "2012-06-30") # vt2012
    create(:occasion, :date => "2012-07-31") # ht2012

    # Not included
    create(:occasion, :date => "2008-12-31") # before initial date
    create(:occasion, :date => Date.today + 1.year) # Not this year

    get :index
    assert_response :success
    assert_equal    %w(ht2009 vt2010 vt2012 ht2012), assigns(:terms)
  end

  test "visitors, all events" do
    vt2012 = create(:occasion, :date => "2012-06-30")
    ht2012 = create(:occasion, :date => "2012-07-31")
    vt2013 = create(:occasion, :date => "2013-01-01")

    # No tsv
    get :visitors, :id => "ht2012"
    assert_response :success
    assert_equal    [ht2012.event], assigns(:events)

    # tsv
    Event.expects(:get_visitor_stats_for_events).with("ht2012", [ht2012.event]).returns([
      {
        "district_name" => "district name",
        "school_name"   => "school name",
        "group_name"    => "group name",
        "event_name"    => "event name",
        "num_booked"    => 10,
        "num_children"  => 9,
        "num_adult"     => 1
      }
    ])
    @controller.expects(:send_csv).with(
      "besokstatistik_ht2012.tsv",
      "Stadsdel\tSkola\tGrupp\tFöreställning\tAntal bokade\tAntal barn\tAntal vuxna\ndistrict name\tschool name\tgroup name\tevent name\t10\t9\t1\n"
    ).returns(true)

    @controller.expects(:render).returns(true) # When mocking send_csv, the view is rendered

    get :visitors, :id => "ht2012", :format => "xls"
  end
  test "visitors, single event" do
    vt2012 = create(:occasion, :date => "2012-06-30")
    ht2012 = create(:occasion, :date => "2012-07-31")
    vt2013 = create(:occasion, :date => "2013-01-01")

    # No tsv
    Event.expects(:get_visitor_stats_for_events).with("ht2012", [vt2013.event]).returns([])

    get :visitors, :id => "ht2012", :event_id => vt2013.event.id
    assert_response :success
    assert_equal    vt2013.event,   assigns(:event)
    assert_equal    [vt2013.event], assigns(:events)
    assert_equal    [],             assigns(:visitor_stats)

    # tsv
    Event.expects(:get_visitor_stats_for_events).with("vt2013", [vt2013.event]).returns([
      {
        "district_name" => "district name",
        "school_name"   => "school name",
        "group_name"    => "group name",
        "event_name"    => "event name",
        "num_booked"    => 10,
        "num_children"  => 9,
        "num_adult"     => 1
      }
    ])
    @controller.expects(:send_csv).with(
      "besokstatistik_vt2013.tsv",
      "Stadsdel\tSkola\tGrupp\tFöreställning\tAntal bokade\tAntal barn\tAntal vuxna\ndistrict name\tschool name\tgroup name\tevent name\t10\t9\t1\n"
    ).returns(true)

    get :visitors, :id => "vt2013", :event_id => vt2013.event.id, :format => "xls"
  end

  test "questionnaires, all events" do
    vt2012                  = create(:occasion, :date => "2012-06-30")
    ht2012                  = create(:occasion, :date => "2012-07-31")
    ht2012_no_questionnaire = create(:occasion, :date => "2012-07-31")
    ht2012_no_answer_form   = create(:occasion, :date => "2012-07-31")
    vt2013                  = create(:occasion, :date => "2013-01-01")

    questionnaire = create(:questionnaire, :event => ht2012.event)
    create(:questionnaire, :event => ht2012_no_answer_form.event)

    create(:answer_form, :questionnaire => questionnaire)

    get :questionnaires, :id => "ht2012"
    assert_response :success
    assert_equal    [ht2012.event], assigns(:events)
  end
  test "questionnaires, single event" do
    # Setup occasion
    vt2012                  = create(:occasion, :date => "2012-06-30")
    ht2012                  = create(:occasion, :date => "2012-07-31")
    ht2012_no_questionnaire = create(:occasion, :date => "2012-07-31")
    ht2012_no_answer_form   = create(:occasion, :date => "2012-07-31")
    vt2013                  = create(:occasion, :date => "2013-01-01")

    # Setup questionnaires
    questionnaire = create(:questionnaire, :event => ht2012.event)
    dummy_q       = create(:questionnaire, :event => ht2012_no_answer_form.event)
    answer_form   = create(:answer_form, :questionnaire => questionnaire, :completed => true)
    dummy_a       = create(:answer_form, :questionnaire => questionnaire)

    # Setup questions
    mark = create(:question, :question => "mark", :qtype => "QuestionMark")
    text = create(:question, :question => "text", :qtype => "QuestionText")
    bool = create(:question, :question => "bool", :qtype => "QuestionBool")
    m_ch = create(:question, :question => "m_ch", :qtype => "QuestionMchoice", :choice_csv => "foo,bar")

    questionnaire.questions << mark
    questionnaire.questions << text
    questionnaire.questions << bool
    questionnaire.questions << m_ch

    # Setup answers
    create(:answer, :answer_form => answer_form, :question => mark, :answer_text => "4")
    create(:answer, :answer_form => answer_form, :question => text, :answer_text => "text")
    create(:answer, :answer_form => answer_form, :question => bool, :answer_text => "1")
    create(:answer, :answer_form => answer_form, :question => m_ch, :answer_text => "--- !map:HashWithIndifferentAccess \n\"foo\": \"1\"\n\"baz\": \"1\"\n")

    # Errors
    get :questionnaires, :id => "ht2012", :event_id => ht2012_no_questionnaire.event.id
    assert_redirected_to :action => "questionnaires"
    assert_equal         "Evenemanget saknar enkät eller enkätsvar.", flash[:warning]
    get :questionnaires, :id => "ht2012", :event_id => ht2012_no_answer_form.event.id
    assert_redirected_to :action => "questionnaires"
    assert_equal         "Evenemanget saknar enkät eller enkätsvar.", flash[:warning]

    # No tsv
    get :questionnaires, :id => "ht2012", :event_id => ht2012.event.id
    assert_response :success
    assert_equal    ht2012.event, assigns(:event)

    # tsv
    @controller.expects(:send_csv).with(
      "enkatstatistik_ht2012.tsv",
      "Enkätsvar för #{ht2012.event.name}\nAntal besvarade enkäter\tAntal obesvarade enkäter\n1\t1\n\nFråga\tSvar\nbool (Procent ja-svar , Procent nej-svar)\t0\t100\nm_ch (Antal för varje ord)\tbar\tbaz\tfoo\n\"\"\t0\t1\t1\nmark (Genomsnittssvar)\t4.00\ntext (Alla svar)\ttext\n"
    ).returns(true)

    get :questionnaires, :id => "ht2012", :event_id => ht2012.event.id, :format => "xls"
  end

  test "unbooking_questionnaires" do
    # Setup questionnaires
    questionnaire = Questionnaire.find_unbooking
    answer_form   = create(:answer_form, :questionnaire => questionnaire, :completed => true, :created_at => "2012-08-01 15:00:00")
    dummy_a       = create(:answer_form, :questionnaire => questionnaire, :completed => true)
    dummy_a       = create(:answer_form, :questionnaire => questionnaire,                     :created_at => "2012-08-01 15:00:00")

    # Setup questions
    mark = create(:question, :question => "mark", :qtype => "QuestionMark")
    text = create(:question, :question => "text", :qtype => "QuestionText")
    bool = create(:question, :question => "bool", :qtype => "QuestionBool")
    m_ch = create(:question, :question => "m_ch", :qtype => "QuestionMchoice", :choice_csv => "foo,bar")

    questionnaire.questions << mark
    questionnaire.questions << text
    questionnaire.questions << bool
    questionnaire.questions << m_ch

    # Setup answers
    create(:answer, :answer_form => answer_form, :question => mark, :answer_text => "4")
    create(:answer, :answer_form => answer_form, :question => text, :answer_text => "text")
    create(:answer, :answer_form => answer_form, :question => bool, :answer_text => "1")
    create(:answer, :answer_form => answer_form, :question => m_ch, :answer_text => "--- !map:HashWithIndifferentAccess \n\"foo\": \"1\"\n\"baz\": \"1\"\n")

    # No tsv
    get :unbooking_questionnaires, :id => "ht2012"
    assert_response :success
    assert_equal    "ht2012", assigns(:term)
    assert_equal    questionnaire, assigns(:questionnaire)
    assert_equal    [answer_form, dummy_a], assigns(:answer_forms)

    # tsv
    @controller.expects(:send_csv).with(
      "avbokningsstatistik_ht2012.tsv",
      "Avbokningsenkätsvar\nAntal besvarade enkäter\tAntal obesvarade enkäter\n2\t1\n\nFråga\tSvar\nbool (Procent ja-svar , Procent nej-svar)\t0\t100\nm_ch (Antal för varje ord)\tbar\tbaz\tfoo\n\"\"\t0\t1\t1\nmark (Genomsnittssvar)\t4.00\ntext (Alla svar)\ttext\n"
    ).returns(true)

    get :unbooking_questionnaires, :id => "ht2012", :format => "xls"
  end
end
