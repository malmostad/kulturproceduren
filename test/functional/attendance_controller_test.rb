require 'test_helper'

class AttendanceControllerTest < ActionController::TestCase
  def setup
    # Stub ActionController filters
    @controller.expects(:authenticate).at_least_once.returns(true)

    @event     = create(:event, :ticket_state => Event::FREE_FOR_ALL)
    @occasions = create_list(:occasion, 3, :event => @event, :date => Date.today - 1)
    @occasion  = @occasions.first
    @user      = create(:user, :roles => [roles(:host)])
    session[:current_user_id] = @user.id

    # Not reportable
    @not_reportable_occasion = create(:occasion, :event => @event, :date => Date.today + 1)
  end

  test "entity loading" do
    get :index
    assert_redirected_to root_url()
    assert_equal "Felaktig adress angiven", flash[:error]
    get :report
    assert_redirected_to root_url()
    assert_equal "Felaktig adress angiven", flash[:error]
    post :update_report
    assert_redirected_to root_url()
    assert_equal "Felaktig adress angiven", flash[:error]
  end
  test "require host" do
    user = create(:user, :roles => [roles(:booker)])
    session[:current_user_id] = user.id
    get :report, :event_id => @event.id
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att rapportera närvaro", flash[:error]
    post :update_report, :event_id => @event.id
    assert_redirected_to root_url()
    assert_equal "Du har inte behörighet att rapportera närvaro", flash[:error]
  end

  test "index" do
    # Event
    get :index, :event_id => @event.id
    assert_response :success
    assert_equal @event, assigns(:event)

    # Occasion
    get :index, :occasion_id => @occasion.id
    assert_response :success
    assert_equal @occasion, assigns(:occasion)
    assert_equal @event, assigns(:event)
  end
  test "index pdf" do
    @controller.expects(:render).twice
    @controller.expects(:generate_pdf).twice.returns(stub(:render => "render called"))
    @controller.expects(:send_data).with(
      "render called",
      :filename => "narvaro.pdf",
      :type => "application/pdf",
      :disposition => "inline"
    ).twice

    # Event
    get :index, :event_id => @event.id, :format => "pdf"
    assert_response :success
    assert_equal @event, assigns(:event)

    # Occasion
    get :index, :occasion_id => @occasion.id, :format => "pdf"
    assert_response :success
    assert_equal @occasion, assigns(:occasion)
    assert_equal @event, assigns(:event)
  end

  test "report" do
    # Event
    get :report, :event_id => @event.id
    assert_response :success

    # Occasion
    get :report, :occasion_id => @occasion.id
    assert_response :success

    # Occasion, upcoming
    @occasion.date = Date.today + 1
    @occasion.save
    get :report, :occasion_id => @occasion.id
    assert_redirected_to occasion_attendance_index_url(@occasion)
    assert_equal "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit", flash[:error]
  end

  def book(group, occasion, student_count, adult_count = 0, wheelchair_count = 0)
    create(
      :booking,
      :group => group,
      :occasion => occasion,
      :student_count => student_count,
      :adult_count => adult_count,
      :wheelchair_count => wheelchair_count
    )
  end

  test "update report for occasion" do
    # Booking setup
    groups = create_list(:group, 3)
    create(:allotment, :event => @event, :amount => 15)

    assert_equal 15, Ticket.count(:all)
    assert groups.first.tickets.empty?
    assert groups.second.tickets.empty?
    assert groups.third.tickets.empty?

    book(groups.first,  @occasions.first, 3, 1)
    book(groups.second, @occasions.first, 4, 2, 1)
    book(groups.third,  @occasions.first, 1, 1)

    assert_equal 4, groups.first.tickets.count(:conditions => { :state => Ticket::BOOKED })
    assert_equal 7, groups.second.tickets.count(:conditions => { :state => Ticket::BOOKED })
    assert_equal 2, groups.third.tickets.count(:conditions => { :state => Ticket::BOOKED })

    post(
      :update_report,
      :occasion_id => @occasions.first.id,
      :attendance => {
        @occasions.first.id.to_s => {
          groups.first.id.to_s  => { "normal" => "2", "adult" => "1" },
          groups.second.id.to_s => { "normal" => "4", "adult" => "1", "wheelchair" => "1" },
          groups.third.id.to_s  => { "normal" => "2", "adult" => "2", "wheelchair" => "1" },
        }
      }
    )

    assert_redirected_to report_occasion_attendance_url(@occasions.first)
    assert_equal "Närvaron uppdaterades.", flash[:notice]

    # First group
    tickets = groups.first.tickets(true).to_a
    assert_equal 2, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::NOT_USED }.length
    assert_equal 0, tickets.find_all { |t| t.state == Ticket::BOOKED }.length

    # Second group
    tickets = groups.second.tickets(true).to_a
    assert_equal 4, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t| !t.adult &&  t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::NOT_USED }.length
    assert_equal 0, tickets.find_all { |t| t.state == Ticket::BOOKED }.length

    # Third group, more reported than booked
    tickets = groups.third.tickets(true).to_a
    assert_equal 2, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 2, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t| !t.adult &&  t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 0, tickets.find_all { |t| t.state == Ticket::BOOKED || t.state == Ticket::NOT_USED }.length
  end
  test "update report for event" do
    # Booking setup
    groups = create_list(:group, 4)
    create(:allotment, :event => @event, :amount => 20)

    assert_equal 20, Ticket.count(:all)
    assert groups.first.tickets.empty?
    assert groups.second.tickets.empty?
    assert groups.third.tickets.empty?
    assert groups.fourth.tickets.empty?

    book(groups.first,  @occasions.first,         3, 1)
    book(groups.second, @occasions.second,        4, 2, 1)
    book(groups.third,  @occasions.third,         1, 1)
    book(groups.fourth, @not_reportable_occasion, 1, 1)

    assert_equal 4, groups.first.tickets.count(:conditions => { :state => Ticket::BOOKED })
    assert_equal 7, groups.second.tickets.count(:conditions => { :state => Ticket::BOOKED })
    assert_equal 2, groups.third.tickets.count(:conditions => { :state => Ticket::BOOKED })
    assert_equal 2, groups.fourth.tickets.count(:conditions => { :state => Ticket::BOOKED })

    post(
      :update_report,
      :event_id => @event.id,
      :attendance => {
        @occasions.first.id.to_s => {
          groups.first.id.to_s  => { "normal" => "2", "adult" => "1" }
        },
        @occasions.second.id.to_s => {
          groups.second.id.to_s => { "normal" => "4", "adult" => "1", "wheelchair" => "1" }
        },
        @occasions.third.id.to_s => {
          groups.third.id.to_s  => { "normal" => "2", "adult" => "2", "wheelchair" => "1" }
        },
        @not_reportable_occasion.id.to_s => {
          groups.fourth.id.to_s => { "normal" => "1", "adult" => "1" }
        }
      }
    )

    assert_redirected_to report_event_attendance_url(@event)
    assert_equal "Närvaron uppdaterades.", flash[:notice]

    # First group
    tickets = groups.first.tickets(true).to_a
    assert_equal 2, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::NOT_USED }.length
    assert_equal 0, tickets.find_all { |t| t.state == Ticket::BOOKED }.length

    # Second group
    tickets = groups.second.tickets(true).to_a
    assert_equal 4, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t| !t.adult &&  t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::NOT_USED }.length
    assert_equal 0, tickets.find_all { |t| t.state == Ticket::BOOKED }.length

    # Third group, more reported than booked
    tickets = groups.third.tickets(true).to_a
    assert_equal 2, tickets.find_all { |t| !t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 2, tickets.find_all { |t|  t.adult && !t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 1, tickets.find_all { |t| !t.adult &&  t.wheelchair && t.state == Ticket::USED }.length
    assert_equal 0, tickets.find_all { |t| t.state == Ticket::BOOKED || t.state == Ticket::NOT_USED }.length

    # Fourth group, unreportable occasion
    tickets = groups.fourth.tickets(true).to_a
    assert_equal 2, tickets.find_all { |t| t.state == Ticket::BOOKED }.length
  end

  test "update report, upcoming occasion" do
    # Occasion, upcoming
    @occasion.date = Date.today + 1
    @occasion.save
    post :update_report, :occasion_id => @occasion.id
    assert_redirected_to root_url()
    assert_equal "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit", flash[:error]
  end

  #test "generate pdf" do
  #  # TODO
  #end
end
