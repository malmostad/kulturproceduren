FactoryGirl.define do
  factory :district do
    sequence(:name) { |n| "District #{n}" }
    contacts        { "#{FactoryGirl.generate(:email)},#{FactoryGirl.generate(:email)}" }
    elit_id         nil
    extens_id       { |n| "id_#{n}" }

    factory :district_with_schools do
      ignore { school_count 5 }
      after_create do |district, evaluator|
        FactoryGirl.create_list(:school, evaluator.school_count, :district => district)
      end
    end
    factory :district_with_groups do
      ignore do
        school_count 5
        group_count  5
      end
      after_create do |district, evaluator|
        FactoryGirl.create_list(:school, evaluator.school_count, :district => district).each do |school|
          FactoryGirl.create_list(:group, evaluator.group_count, :school => school)
        end
      end
    end
    factory :district_with_age_groups do
      ignore do
        school_count   5
        group_count    5
        age_group_data [[10,20]] # [ [ :age1, :quantity1 ], [ :age2, :quantity2 ] ... ]
      end
      after_create do |district, evaluator|
        FactoryGirl.create_list(:school, evaluator.school_count, :district => district).each do |school|
          FactoryGirl.create_list(:group, evaluator.group_count, :school => school).each do |group|
            evaluator.age_group_data.each do |age, quantity|
              FactoryGirl.create(:age_group, :group => group, :age => age, :quantity => quantity)
            end
          end
        end
      end
    end
  end

  factory :school do
    district
    sequence(:name) { |n| "School #{n}" }
    contacts        { "#{FactoryGirl.generate(:email)},#{FactoryGirl.generate(:email)}" }
    elit_id         nil
    extens_id       { |n| "id_#{n}" }

    factory :school_with_groups do
      ignore do
        group_count  5
      end
      after_create do |school, evaluator|
        FactoryGirl.create_list(:group, evaluator.group_count, :school => school)
      end
    end
    factory :school_with_age_groups do
      ignore do
        group_count    5
        age_group_data [[10,20]] # [ [ :age1, :quantity1 ], [ :age2, :quantity2 ] ... ]
      end
      after_create do |school, evaluator|
        FactoryGirl.create_list(:group, evaluator.group_count, :school => school).each do |group|
          evaluator.age_group_data.each do |age, quantity|
            FactoryGirl.create(:age_group, :group => group, :age => age, :quantity => quantity)
          end
        end
      end
    end
  end

  factory :group do
    school
    sequence(:name)      { |n| "Group #{n}" }
    contacts             { "#{FactoryGirl.generate(:email)},#{FactoryGirl.generate(:email)}" }
    elit_id              nil
    sequence(:extens_id) { |n| "id_#{n}" }
    active               true
    sequence(:priority)

    factory :group_with_age_groups do
      ignore do
        age_group_data [[10,20]] # [ [ :age1, :quantity1 ], [ :age2, :quantity2 ] ... ]
      end
      after_create do |group, evaluator|
        evaluator.age_group_data.each do |age, quantity|
          FactoryGirl.create(:age_group, :group => group, :age => age, :quantity => quantity)
        end
      end
    end
  end

  factory :age_group do
    group
    age      10
    quantity 20
  end

  factory :role do
    name "dummy"
  end

  factory :role_application do
    user
    role
    group                     nil
    culture_provider          nil
    message                   "role application"
    new_culture_provider_name nil
    state                     RoleApplication::PENDING
    response                  nil
  end

  factory :user do
    sequence(:username)   { |n| "user_#{n}" }
    salt                  "abcdefg"
    password              "password"
    password_confirmation { password }
    name                  { username }
    email                 { "#{username}@example.com" }
    cellphone             "012 - 34 567"
    districts             { [FactoryGirl.create(:district)] }
    roles                 { [] }
  end


  factory :culture_provider do
    sequence(:name)          { |n| "culture_provider_#{n}" }
    description              "lorem ipsum dolor sit amet"
    contact_person           "John Doe"
    email                    { "#{name}@example.com" }
    phone                    "012-345 67"
    address                  "Foogatan 13"
    opening_hours            "08:00 - 19:00"
    url                      "http://www.malmo.se/"
    main_image_id            nil
    map_address              "Foogatan 13"
    active                   true

    linked_culture_providers { [] }
    linked_events            { [] }
  end

  factory :event do
    culture_provider
    sequence(:name)              { |n| "event_#{n}" }
    description                  "lorem ipsum dolor sit amet"
    visible_from                 Date.today - 1
    visible_to                   Date.today + 1
    from_age                     10
    to_age                       11
    further_education            false
    ticket_release_date          nil
    ticket_state                 nil
    url                          "http://www.malmo.se"
    movie_url                    "http://www.malmo.se"
    opening_hours                "08:00 - 19:00"
    cost                         "40 kr"
    booking_info                 "lorem ipsum"
    main_image_id                nil
    map_address                  "Foogatan 13"
    single_group_per_occasion    false
    district_transition_date     nil
    free_for_all_transition_date nil
    bus_booking                  false

    linked_culture_providers     { [] }
    linked_events                { [] }

    factory :event_with_occasions do
      ignore do
        occasion_count 5
        occasion_dates [ Date.today ] # Allows for an array occasion dates for the children
      end

      after_create do |event, evaluator|
        dates = evaluator.occasion_dates
        len = dates.length

        1.upto(evaluator.occasion_count) do |i|
          FactoryGirl.create(:occasion,
            :event => event,
            :date => evaluator.occasion_dates[(i-1)%len] # Cycle through the occasion dates
          )
        end
      end
    end
  end

  factory :occasion do
    association      :event, :factory => :event, :ticket_state => :alloted_group, :ticket_release_date => Date.today - 1
    date             Date.today
    start_time       (Time.zone.now + 1.hour).strftime("%H:%M")
    stop_time        (Time.zone.now + 2.hours).strftime("%H:%M")
    seats            30
    wheelchair_seats 3
    address          "Foogatan 13"
    description      "lorem ipsum dolor sit amet"
    telecoil         true
    cancelled        false
    map_address      "Foogata 13"
    single_group     false

    factory :occasion_with_booked_tickets do
      ignore do
        ticket_count 5
      end
      after_create do |occasion, evaluator|
        FactoryGirl.create_list(:ticket, evaluator.ticket_count,
          :event => occasion.event,
          :occasion => occasion,
          :state => :booked
        )
      end
    end
  end

  factory :allotment do
    amount   100
    user
    event
    district nil
    group    nil
  end

  factory :booking do
    booked_at        Time.now - 1.day
    unbooked         false
    unbooked_at      nil
    unbooked_by_id   nil
    student_count    10
    adult_count      2
    wheelchair_count 1
    requirement      "Requirements"
    companion_name   "Foo Bar"
    companion_phone  "031-12345678"
    companion_email  "foo.bar@example.com"
    bus_booking      false
    bus_one_way      false
    bus_stop         nil
    group
    occasion
    user

    ignore { skip_tickets false }

    after_build do |booking, evaluator|
      if !evaluator.skip_tickets
        FactoryGirl.create_list(
          :ticket,
          evaluator.student_count.to_i + evaluator.adult_count.to_i + evaluator.wheelchair_count.to_i,
          :booking => nil,
          :group => evaluator.group,
          :district => evaluator.group.try(:school).try(:district),
          :occasion => evaluator.occasion,
          :event => evaluator.occasion.try(:event),
          :state => :unbooked
        )
      end
    end
  end

  factory :ticket do
    event
    group       nil
    occasion    nil
    district    nil
    user        nil
    booking     nil
    allotment   nil
    state       0
    adult       false
    wheelchair  false
    booked_when nil
  end

  factory :category_group do
    sequence(:name)     { |n| "category_group_#{n}" }
    visible_in_calendar true
  end
  factory :category do
    category_group
    sequence(:name) { |n| "category_#{n}" }
  end

  factory :booking_requirement do
    group
    occasion
    requirement "requirements"
  end

  factory :notification_request do
    event
    group
    user
    send_mail true
    send_sms  false
    target_cd 1
  end

  factory :image do
    event
    culture_provider
    description  "an image"
    filename     "foo.jpg"
    width        640
    height       480
    thumb_width  320
    thumb_height 240
  end

  factory :question do
    qtype               "QuestionText"
    sequence(:question) { |n| "Question #{n}" }
    choice_csv          nil
    template            false
    mandatory           false
  end
  factory :questionnaire do
    event
    description "A questionnaire"
    target_cd   1
  end
  factory :answer_form do
    completed false
    occasion
    group
    questionnaire
    booking nil
  end
  factory :answer do
    question
    answer_form
    answer_text "yes"
  end

  factory :attachment do
    event
    description  "description"
    filename     "filename.pdf"
    content_type "application/pdf"
  end
end
