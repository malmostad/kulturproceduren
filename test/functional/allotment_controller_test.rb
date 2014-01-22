# -*- encoding : utf-8 -*-
require 'test_helper'

class AllotmentControllerTest < ActionController::TestCase
  def setup
    # Stub ActionController filters
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)

    # Base data
    @districts = create_list(:district, 2)
    @schools   = @districts.collect { |d| create_list(:school, 2, :district => d) }.flatten
    @groups    = []
    @schools.collect do |s|
      groups = create_list(:group, 3, :school => s)
      # group index n+0
      create(:age_group, :age =>  9, :quantity => 10, :group => groups.first)
      # group index n+1
      create(:age_group, :age => 10, :quantity => 15, :group => groups.second)
      # group index n+2
      create(:age_group, :age => 11, :quantity => 20, :group => groups.third)
      # dummy groups
      groups.each do |g|
        create(:age_group, :age =>  5, :quantity => 11, :group => g)
        create(:age_group, :age => 16, :quantity => 11, :group => g)
      end
      @groups += groups
    end

    @event = create(:event, :from_age => 9, :to_age => 11, :ticket_state => :alloted_group)
  end

  test "wrong event" do
    get :init, :id => -1
    assert_redirected_to :controller => "events", :action => "index"
    assert_equal "Ett giltigt evenemang måste väljas för fördelning av biljetter.", flash[:error]
    post :assign_params, :id => -1
    assert_redirected_to :controller => "events", :action => "index"
    assert_equal "Ett giltigt evenemang måste väljas för fördelning av biljetter.", flash[:error]
    get :create_free_for_all_tickets, :id => -1
    assert_redirected_to :controller => "events", :action => "index"
    assert_equal "Ett giltigt evenemang måste väljas för fördelning av biljetter.", flash[:error]
    get :distribute, :id => -1
    assert_redirected_to :controller => "events", :action => "index"
    assert_equal "Ett giltigt evenemang måste väljas för fördelning av biljetter.", flash[:error]
    post :create_tickets, :id => -1
    assert_redirected_to :controller => "events", :action => "index"
    assert_equal "Ett giltigt evenemang måste väljas för fördelning av biljetter.", flash[:error]
    delete :destroy, :id => -1
    assert_redirected_to :controller => "events", :action => "index"
    assert_equal "Ett giltigt evenemang måste väljas för fördelning av biljetter.", flash[:error]
  end

  test "init" do
    get :init, :id => @event.id
    assert_response :success
    assert_equal District.all(:order => "name ASC"), assigns(:districts)
  end

  def build_params(override = {})
   {
     :release_date => (Date.today + 10).to_s,
     :num_tickets  => "10",
     :ticket_state => Event::ALLOTED_GROUP.to_s,
     :district_ids => %w(-1)
   }.merge(override)
  end

  test "assign params with fewest possible parameters" do
    allotment_params = build_params() 

    post :assign_params, :id => @event.id, :allotment => allotment_params

    assert_redirected_to :action => "distribute", :id => @event.id

    assert_equal Date.today + 10, session[:allotment][:release_date]
    assert_equal 10,              session[:allotment][:num_tickets]
    assert_equal :alloted_group,  session[:allotment][:ticket_state]
    assert_equal false,           session[:allotment][:bus_booking]

    assert_nil   session[:allotment][:district_ids]
    assert_nil   session[:allotment][:district_transition_date]
    assert_nil   session[:allotment][:free_for_all_transition_date]
  end

  test "assign params for free for all with all common parameters" do
    district = District.first
    allotment_params = build_params(
      :district_transition_date     => (Date.today + 11).to_s,
      :free_for_all_transition_date => (Date.today + 12).to_s,
      :district_ids                 => [district.id.to_s],
      :ticket_state                 => Event::FREE_FOR_ALL.to_s,
      :bus_booking                  => "1"
    )

    post :assign_params, :id => @event.id, :allotment => allotment_params

    assert_redirected_to :action => "create_free_for_all_tickets", :id => @event.id

    assert_equal Date.today + 10, session[:allotment][:release_date]
    assert_equal Date.today + 11, session[:allotment][:district_transition_date]
    assert_equal Date.today + 12, session[:allotment][:free_for_all_transition_date]
    assert_equal 10,              session[:allotment][:num_tickets]
    assert_equal :free_for_all,   session[:allotment][:ticket_state]
    assert_equal [district.id],   session[:allotment][:district_ids]
    assert_equal true,            session[:allotment][:bus_booking]
  end

  test "assign params with existing tickets" do
    groups = [
      District.first.schools.first.groups.first,
      District.first.schools.second.groups.first,
      create(:group_with_age_groups, :age_group_data => [[5, 10]])
    ]

    # Districts from the groups, the odd group district, and a district from the parameters
    param_district = create(:district)
    expected_districts = [District.first, groups.last.school.district].sort_by(&:name).collect(&:id)
    expected_districts << param_district.id

    groups.each { |g| create(:allotment, :event => @event, :group => g, :district => g.school.district, :amount => 3) }
    allotment_params = build_params(
      :ticket_state => Event::FREE_FOR_ALL,
      :district_ids => [param_district.id]
    )

    post :assign_params, :id => @event.id, :allotment => allotment_params

    assert_redirected_to :action => "distribute", :id => @event.id

    assert_equal 19,                 session[:allotment][:num_tickets]  # params + existing tickets
    assert_equal :alloted_group,     session[:allotment][:ticket_state] # can't override the ticket state
    assert_equal expected_districts, session[:allotment][:district_ids] # see comment above
    assert_equal [groups.last.id],   session[:allotment][:extra_groups] # odd group
  end

  def expected_distribution(*group_indexes)
    expected = {}
    # Extra ticket for adult
    group_indexes.each { |i| expected[@groups[i].id] = @groups[i].age_groups.num_children_by_age_span(@event.from_age, @event.to_age) + 1 }
    return expected
  end

  test "preliminary distribution with basic parameters" do
    # 24 tickets = enough for the first group with age 9 in both districts
    allotment_params = build_params(:num_tickets => 24)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    # Expect the groups with age 9
    assert_equal expected_distribution(0, 6), session[:allotment][:working_distribution]
  end
  test "preliminary distribution with enough tickets for multiple groups" do
    # 56 tickets = enough for the groups with age 9 and ten in both districts
    allotment_params = build_params(:num_tickets => 56)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    # Expect the groups with age 9 and 10
    assert_equal expected_distribution(0, 1, 6, 7), session[:allotment][:working_distribution]
  end
  test "preliminary distribution with changed priorities" do
    @groups[5].move_first_in_prio
    @groups[11].move_first_in_prio
    # 42 tickets = enough for the two groups above, both have 20 children
    allotment_params = build_params(:num_tickets => 42)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    # Expect the groups with age 9
    assert_equal expected_distribution(5, 11), session[:allotment][:working_distribution]
  end
  test "preliminary distribution with different amount of children in the districts" do
    # District with double the amount of children
    district = create(:district)
    schools  = create_list(:school, 2, :district => district)
    groups   = []
    schools.collect do |s|
      g = create_list(:group, 3, :school => s)
      create(:age_group, :age =>  9, :quantity => 20, :group => g.first)
      create(:age_group, :age => 10, :quantity => 30, :group => g.second)
      create(:age_group, :age => 11, :quantity => 40, :group => g.third)
      groups += g
    end

    # 48 tickets = enough for the first group with age 9 in all districts
    # The first two districts get 12 tickets each, the one created in this test
    # gets 24 tickets
    allotment_params = build_params(:num_tickets => 48)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    # Expect the groups with age 9
    expected = expected_distribution(0, 6).merge(groups[0].id => groups[0].age_groups.num_children_by_age_span(@event.from_age, @event.to_age) + 1)
    assert_equal expected, session[:allotment][:working_distribution]
  end
  test "preliminary distribution with pooled tickets" do
    # 40 tickets means 20 per district. That is enough for the first group (age 9) in
    # the first district but not enought for the second (age 10). This means 9 tickets
    # will pool from the first district and be available for the second. 29 tickets
    # for the second district is enough for the first two groups (age 9 and 10).
    allotment_params = build_params(:num_tickets => 40)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    assert_equal expected_distribution(0, 6, 7), session[:allotment][:working_distribution]
  end
  test "preliminary distribution for districts" do
    # District with double the amount of children
    district = create(:district)
    schools  = create_list(:school, 2, :district => district)
    groups   = []
    schools.collect do |s|
      g = create_list(:group, 3, :school => s)
      create(:age_group, :age =>  9, :quantity => 20, :group => g.first)
      create(:age_group, :age => 10, :quantity => 30, :group => g.second)
      create(:age_group, :age => 11, :quantity => 40, :group => g.third)
      groups += g
    end

    allotment_params = build_params(:num_tickets => 80, :ticket_state => Event::ALLOTED_DISTRICT.to_s)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    distribution = session[:allotment][:working_distribution]
    assert_equal distribution[@districts.first.id],     distribution[@districts.second.id]
    assert_equal 2 * distribution[@districts.first.id], distribution[district.id]
  end
  test "ticket distribution for groups" do
    # Include an extra not targeted group
    extra_group = create(:group)
    create(:allotment, :amount => 10, :event => @event, :group => @groups[2],  :district => @groups[2].school.district)
    create(:allotment, :amount => 20, :event => @event, :group => @groups[8],  :district => @groups[8].school.district)
    create(:allotment, :amount => 5, :event => @event,  :group => extra_group, :district => extra_group.school.district)

    allotment_params = build_params(:num_tickets => 0)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    # The working distribution contains 0 values for all targeted groups
    expected = {}
    @groups.each { |g| expected[g.id] = 0 }

    assert_equal expected.merge(@groups[2].id => 10, @groups[8].id => 20, extra_group.id => 5), session[:allotment][:working_distribution]
  end
  test "ticket distribution for districts" do
    @event.ticket_state = :alloted_district
    @event.save!
    create(:allotment, :amount => 10, :event => @event, :district => @districts.first)
    create(:allotment, :amount => 20, :event => @event, :district => @districts.second)


    allotment_params = build_params(:num_tickets => 0, :ticket_state => Event::ALLOTED_DISTRICT.to_s)
    post :assign_params, :id => @event.id, :allotment => allotment_params

    # The working distribution contains 0 values for all targeted districts
    expected = {}
    District.all.each { |d| expected[d.id] = 0 }

    assert_equal expected.merge(@districts.first.id => 10, @districts.second.id => 20), session[:allotment][:working_distribution]
  end

  test "create free for all tickets" do
    user = create(:user)
    create(:allotment, :amount => 10, :event => @event, :district => @districts.first)
    session[:current_user_id] = user.id
    session[:allotment] = {
      :release_date => (Date.today + 2).to_s,
      :ticket_state => :free_for_all,
      :num_tickets => 11
    }

    post :create_free_for_all_tickets, :id => @event.id

    assert_redirected_to ticket_allotment_event_url(@event)
    assert_equal "Biljetter till evenemanget har fördelats.", flash[:notice]

    @event.reload
    @event.allotments(true)

    assert_nil   session[:allotment]
    assert_equal Date.today + 2, @event.ticket_release_date
    assert_equal :free_for_all,  @event.ticket_state
    assert_equal 1,              @event.allotments.length
    assert_equal 11,             @event.allotments.first.amount
    assert_equal user,           @event.allotments.first.user
  end

  test "distribute" do
    # Base parameters
    session[:allotment] = {
      :district_ids => nil,
      :num_tickets => 100,
      :ticket_state => :alloted_group,
      :working_distribution => {}
    }

    get :distribute, :id => @event.id
    assert_equal District.all(:order => "name ASC"), assigns(:districts)
    assert_equal 100,                                assigns(:tickets_left)
    assert_nil   assigns(:extra_groups)

    # Specific districts
    session[:allotment][:district_ids] = [@districts.first.id]
    get :distribute, :id => @event.id
    assert_equal [@districts.first], assigns(:districts)
    session[:allotment][:district_ids] = nil

    # Extra groups
    extra_groups = create_list(:group, 2)
    session[:allotment][:extra_groups] = extra_groups.collect(&:id)
    get :distribute, :id => @event.id
    assert_equal extra_groups, assigns(:extra_groups)

    # Working distribution
    session[:allotment][:working_distribution] = {
      @groups[1].id         => 10,
      @groups[2].id         => 11,
      @groups[3].id         => 12,
      @groups[7].id         => 13,
      extra_groups.first.id => 14
    }
    get :distribute, :id => @event.id
    assigns(:districts).each do |district|
      case district

      when @districts.first
        assert_equal 33, district.num_tickets
        assert_equal 21, district.distribution_schools.first.num_tickets
        assert_equal 12, district.distribution_schools.second.num_tickets

        district.distribution_schools.first.distribution_groups.each do |g|
          case g.id
          when @groups[1].id
            assert_equal 10, g.num_tickets
          when @groups[2].id
            assert_equal 11, g.num_tickets
          else
            assert_equal 0,  g.num_tickets
          end
        end
        district.distribution_schools.second.distribution_groups.each do |g|
          if g.id == @groups[3].id
            assert_equal 12, g.num_tickets
          else
            assert_equal 0,  g.num_tickets
          end
        end

      when @districts.second
        assert_equal @groups[7].id, district.distribution_schools.first.distribution_groups.second.id
        assert_equal 13,            district.num_tickets
        assert_equal 13,            district.distribution_schools.first.num_tickets
        assert_equal 13,            district.distribution_schools.first.distribution_groups.second.num_tickets
      end
    end
    assert_equal 14,                     assigns(:extra_groups).first.num_tickets
    assert_equal 100 - (10+11+12+13+14), assigns(:tickets_left)

    # District allotment
    session[:allotment][:ticket_state] = :alloted_district
    session[:allotment][:working_distribution] = {
      @districts.first.id  => 11,
      @districts.second.id => 12
    }
    get :distribute, :id => @event.id
    assigns(:districts).each do |district|
      case district
      when @districts.first
        assert_equal 11, district.num_tickets
      when @districts.second
        assert_equal 12, district.num_tickets
      end
    end
    assert_equal 100 - (11+12), assigns(:tickets_left)
  end

  test "create tickets for groups" do
    user = create(:user)
    create(:allotment, :amount => 10, :event => @event, :district => @districts.first)
    session[:current_user_id] = user.id
    session[:allotment] = {
      :release_date                 => Date.today + 11,
      :district_transition_date     => Date.today + 12,
      :free_for_all_transition_date => Date.today + 13,
      :ticket_state                 => :alloted_group,
      :num_tickets                  => 30,
      :bus_booking                  => "1"
    }

    post :create_tickets,
      :id => @event.id,
      :allotment => { :ticket_assignment => { @groups[1].id => 11, @groups[4].id => 12 }},
      :create_tickets => true
    assert_redirected_to ticket_allotment_event_url(@event)
    assert_nil session[:allotment]
    assert_equal "Biljetter till evenemanget har fördelats.", flash[:notice]

    @event.reload
    assert_equal Date.today + 11, @event.ticket_release_date
    assert_equal Date.today + 12, @event.district_transition_date
    assert_equal Date.today + 13, @event.free_for_all_transition_date
    assert_equal :alloted_group,  @event.ticket_state
    assert_equal true,            @event.bus_booking

    @event.allotments(true)
    assert_equal 3, @event.allotments.length # 2 groups + extra tickets
    @event.allotments.all(:conditions => "group_id is not null").each do |allotment|
      assert_equal allotment.group.school.district, allotment.district
      assert_equal user,                            allotment.user

      case allotment.group
      when @groups[1]
        assert_equal 11, allotment.amount
      when @groups[4]
        assert_equal 12, allotment.amount
      else
        flunk("Unexpected group")
      end
    end
    extra_allotments = @event.allotments.all(:conditions => "group_id is null")
    assert_equal 1,    extra_allotments.length
    assert_equal 7,    extra_allotments.first.amount
    assert_equal user, extra_allotments.first.user

    last_prio_groups = Group.all(:order => "priority desc", :limit => 2)
    assert last_prio_groups.include?(@groups[1])
    assert last_prio_groups.include?(@groups[4])
  end
  test "create tickets for districts" do
    user = create(:user)
    create(:allotment, :amount => 10, :event => @event)
    session[:current_user_id] = user.id
    session[:allotment] = {
      :release_date                 => Date.today + 12,
      :district_transition_date     => Date.today + 13,
      :free_for_all_transition_date => Date.today + 14,
      :ticket_state                 => :alloted_district,
      :num_tickets                  => 30
    }

    post :create_tickets,
      :id => @event.id,
      :allotment => { :ticket_assignment => { @districts.first.id => 11, @districts.second.id => 12 }},
      :create_tickets => true
    assert_redirected_to ticket_allotment_event_url(@event)
    assert_nil session[:allotment]
    assert_equal "Biljetter till evenemanget har fördelats.", flash[:notice]

    @event.reload
    assert_equal Date.today + 12,   @event.ticket_release_date
    assert_equal Date.today + 13,   @event.district_transition_date
    assert_equal Date.today + 14,   @event.free_for_all_transition_date
    assert_equal :alloted_district, @event.ticket_state

    @event.allotments(true)
    assert_equal 3, @event.allotments.length # 2 groups + extra tickets
    @event.allotments.all(:conditions => "allotments.district_id is not null").each do |allotment|
      assert_equal user, allotment.user
      assert_nil   allotment.group

      case allotment.district
      when @districts.first
        assert_equal 11, allotment.amount
      when @districts.second
        assert_equal 12, allotment.amount
      else
        flunk("Unexpected district")
      end
    end
    extra_allotments = @event.allotments.all(:conditions => "allotments.district_id is null")
    assert_equal 1,    extra_allotments.length
    assert_equal 7,    extra_allotments.first.amount
    assert_equal user, extra_allotments.first.user
  end

  test "add extra groups" do
    # No previous extra groups
    session[:allotment] = {}
    post :create_tickets,
      :id => @event.id,
      :allotment => { :ticket_assignment => { "1" => "0", "2" => "1" }},
      :add_group => { :group_id => "3" }
    assert_redirected_to :action => "distribute", :id => @event.id
    assert_equal({ 2 => 1}, session[:allotment][:working_distribution])
    assert_equal [3],       session[:allotment][:extra_groups]

    # Previous extra groups
    session[:allotment] = { :extra_groups => [3] }
    post :create_tickets,
      :id => @event.id,
      :allotment => { :ticket_assignment => { "1" => "0", "2" => "1" }},
      :add_group => { :group_id => "3" }
    assert_redirected_to :action => "distribute", :id => @event.id
    assert_equal [3],       session[:allotment][:extra_groups]
  end

  test "destroy" do
    create(:allotment, :amount => 10, :event => @event)
    @event.ticket_release_date          = Date.today + 1
    @event.district_transition_date     = Date.today + 2
    @event.free_for_all_transition_date = Date.today + 2
    @event.ticket_state                 = :free_for_all
    @event.save!
    session[:allotment] = {}

    delete :destroy, :id => @event.id
    assert_redirected_to @event
    assert_equal         "Fördelningen togs bort.", flash[:notice]
    assert_nil           session[:allotment]

    @event.reload
    assert_nil   @event.ticket_release_date
    assert_nil   @event.district_transition_date
    assert_nil   @event.free_for_all_transition_date
    assert_nil   @event.ticket_state
  end
end
