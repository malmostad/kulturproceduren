# Methods for generating demo data
namespace :kp do
  namespace :demo do

    desc "Creates a group structure (district/school/group/age group) from demo/group_structure.yml"
    task(create_group_structure: :environment) do
      school_type = SchoolType.find_or_create_by!(name: "Gamla stadsdelar")

      YAML.load_file("#{Rails.root}/demo/group_structure.yml").each do |district_name, schools|

        puts "District \"#{district_name}\""
        district = District.create_with(school_type: school_type).find_or_create_by!(name: district_name)

        schools.each do |school_name, classes|
          puts "\tSchool \"#{school_name}\""
          school = School.find_or_initialize_by(
            name: school_name,
            district: district
          )

          school.save! if school.new_record?

          school.groups.clear

          classes[:from].upto(classes[:to]) do |c|
            if c == 0
              puts "\t\tPre school group"

              group = Group.new do |g|
                g.name = "Förskola"
                g.school = school
              end

              group.save!

              (3..6).each do |i|
                age_group = AgeGroup.new do |a|
                  a.age = i
                  a.quantity = rand(15) + 5
                  a.group = group
                end

                age_group.save!
                puts "\t\t\tAge group: age:#{age_group.age} quantity:#{age_group.quantity}"
              end
            else
              puts "\t\tRegular group \"Klass #{c}\""

              group = Group.new do |g|
                g.name = "Klass #{c}"
                g.school = school
              end

              group.save!

              age_group = AgeGroup.new do |a|
                a.age = c + 6
                a.quantity = rand(20) + 10
                a.group = group
              end
              age_group.save!

              puts "\t\t\tAge group: age:#{age_group.age} quantity:#{age_group.quantity}"

              if rand(6) == 0
                added = 1
                added *= -1 if rand(2) == 0

                extra_age_group = AgeGroup.new do |a|
                  a.age = age_group.age + added
                  a.quantity = rand(3) + 1
                  a.group = group
                end
                extra_age_group.save!

                puts "\t\t\tExtra age group: age:#{extra_age_group.age} quantity:#{extra_age_group.quantity}"
              end
            end
          end
        end
      end

    end

    desc "Creates categories and category groups"
    task(create_categories: :environment) do
      YAML.load_file("#{Rails.root}/demo/categories.yml").each do |group_name, category_names|
        puts "Group: #{group_name}"
        group = CategoryGroup.find_or_create_by_name(group_name)

        group.categories.clear

        category_names.each do |category_name|
          puts "\tCategory: #{category_name}"
          category = Category.new do |c|
            c.name = category_name
            c.category_group = group
          end

          category.save!
        end
      end
    end

    desc "Creates template questions"
    task(create_questions: :environment) do
      YAML.load_file("#{Rails.root}/demo/questions.yml").each do |id, question_data|
        question = Question.new do |q|
          q.qtype = question_data[:type]
          q.question = question_data[:question]
          q.choice_csv = question_data[:choices]
          q.template = true
          q.mandatory = true
        end

        puts "Question: #{question.question}"
        question.save!
      end
    end

    desc "Generates a random culture provider"
    task(generate_culture_provider: :environment) do
      # Culture provider name seeds
      cp_seed = YAML.load_file("#{Rails.root}/demo/culture_provider_seed.yml")
      # Contact person name seeds
      name_seed = YAML.load_file("#{Rails.root}/demo/name_seed.yml")

      count = 1
      count = ENV["count"].to_i if ENV["count"].to_i > 1

      1.upto(count) do
        culture_provider = CultureProvider.new do |c|
          # Generate name from seed
          c.name = cp_seed[:prefix][rand(cp_seed[:prefix].length)] +
            cp_seed[:suffix][rand(cp_seed[:suffix].length)] 
          c.description = IO.read("#{Rails.root}/demo/lorem_ipsum.txt")
          # Generate name from seed
          c.contact_person = name_seed[:first_name][rand(name_seed[:first_name].length)] +
            " " +
            name_seed[:surname][rand(name_seed[:surname].length)]
          c.email = c.contact_person.downcase.gsub(/\W/, "") + "@domain.com"
        end

        puts "Culture provider: #{culture_provider.name}"
        culture_provider.save!
      end
    end

    desc "Lists all culture providers with their ids"
    task(list_culture_providers: :environment) do
      CultureProvider.all(order: "id ASC").each { |cp| puts "#{cp.id}: #{cp.name}" }
    end

    desc "Generates a standing event for a culture provider"
    task(generate_standing_event: :environment) do
      # Seed for event names
      event_seed = YAML.load_file("#{Rails.root}/demo/event_seed.yml")

      cp = CultureProvider.find ENV['culture_provider_id']
      categories = Category.all

      count = 1
      count = ENV["count"].to_i if ENV["count"].to_i > 1

      1.upto(count) do
        event = Event.new do |e|
          e.culture_provider = cp
          # Generate name from seed
          e.name = event_seed[:prefix][rand(event_seed[:prefix].length)] +
            " " + event_seed[:suffix][rand(event_seed[:suffix].length)]
          e.description = IO.read("#{Rails.root}/demo/lorem_ipsum.txt")

          e.visible_from = Date.today - rand(120).days
          e.visible_to = Date.today + rand(120).days

          ages = [rand(20), rand(20)]
          e.from_age = ages.min
          e.to_age = ages.max

          e.further_education = (rand(5) == 0)

          e.categories = categories.reject { |c| rand(3) != 0 }
        end

        puts "Event: #{event.name}"
        event.save!
      end
    end

    desc "Generates an event with occasions for a culture provider"
    task(generate_event: :environment) do
      # Seed for event names
      event_seed = YAML.load_file("#{Rails.root}/demo/event_seed.yml")

      cp = CultureProvider.find ENV['culture_provider_id']
      categories = Category.all
      questions = 

      count = 1
      count = ENV["count"].to_i if ENV["count"].to_i > 1

      1.upto(count) do
        event = Event.new do |e|
          e.culture_provider = cp
          # Generate name from seed
          e.name = event_seed[:prefix][rand(event_seed[:prefix].length)] +
            " " + event_seed[:suffix][rand(event_seed[:suffix].length)]
          e.description = IO.read("#{Rails.root}/demo/lorem_ipsum.txt")

          e.visible_from = Date.today - rand(120).days
          e.visible_to = Date.today + rand(120).days

          ages = [rand(20), rand(20)]
          e.from_age = ages.min
          e.to_age = ages.max

          e.further_education = (rand(5) == 0)

          e.categories = categories.reject { |c| rand(3) != 0 }
        end

        puts "Event: #{event.name}"
        event.save!

        occasion_date = event.visible_from
        occasions = []

        while occasion_date <= event.visible_to
          occasion = Occasion.new do |o|
            o.event = event
            o.date = occasion_date
            o.start_time = occasion_date.to_time.advance(hours: 10 + rand(7))
            o.stop_time = o.start_time.advance(hours: 1 + rand(3))
            o.seats = 25 + rand(175)
            o.wheelchair_seats = rand(10)
            o.address = "n/a"
            o.description = "n/a"
            o.telecoil = (rand(2) == 0);
          end

          puts "\tOccasion: #{occasion.date}"
          occasion.save!

          occasions << occasion
          occasion_date += (1 + rand(7)).days
        end
      end
    end

    desc "Lists events with occasions"
    task(list_events: :environment) do
      Event.all(conditions: [ " events.id in (select x.event_id from occasions x) " ]).each do |e|
        puts "#{e.id}: #{e.name}"
      end
    end

    desc "Creates tickets (not booked/booked/used/not used) for an event"
    task(create_tickets: :environment) do
      # Seed for companion names
      name_seed = YAML.load_file("#{Rails.root}/demo/name_seed.yml")

      event = Event.find ENV["event_id"]

      if event.tickets.empty?
        event.ticket_release_date = event.visible_from
        event.ticket_state = [:alloted_group, :alloted_district, :free_for_all][rand(3)]

        case event.ticket_state
        when :alloted_group
          event.district_transition_date = event.ticket_release_date + 1.week
          event.free_for_all_transition_date = event.ticket_release_date + 2.week
        when :alloted_district
          event.free_for_all_transition_date = event.ticket_release_date + 1.week
        end

        puts event.to_json

        event.save!

        occasions = event.occasions.find(:all)

        groups = Group.all conditions: [
          "id in (select group_id from age_groups where age between ? and ?)",
          event.from_age, event.to_age
        ]

        groups.each do |group|
          next if rand(3) == 0

          occasion = occasions.pop

          companion = Companion.new do |c|
            c.tel_nr = "012345678"
            # Generate companion name from seed
            c.name = name_seed[:first_name][rand(name_seed[:first_name].length)] +
              " " +
              name_seed[:surname][rand(name_seed[:surname].length)]
            c.email = c.name.downcase.gsub(/\W/, "") + "@domain.com"
          end

          puts "Companion: #{companion.name}"
          companion.save!

          puts "Tickets: #{group.name}"
          1.upto(1 + group.age_groups.num_children_by_age_span(event.from_age, event.to_age)) do |i|

            companion.save
            ticket = Ticket.new do |t|
              t.group = group
              t.event = event
              t.district = group.school.district

              if occasion
                t.occasion = occasion
                t.companion = companion
                t.adult = (i == 1)
                t.user_id = 1
                t.wheelchair = false
                t.booked_when = occasion.date.to_time
                if occasion.date < Date.today
                  t.state = rand(10) == 0 ? :not_used : :used
                else
                  t.state = :booked
                end
              else
                t.state = :unbooked
              end
            end

            ticket.save!
          end
        end
      end
    end

    desc "Creates questionnaires with answers for already passed occasions"
    task(create_questionnaires: :environment) do
      event = Event.find ENV["event_id"]

      unless event.questionnaire
        questionnaire = Questionnaire.new do |q|
          q.event = event
          q.description = "n/a"
          q.questions = Question.find(:all , conditions: { template: true })
        end

        puts "Questionnaire"
        questionnaire.save!

        unless event.tickets.empty?
          query = "select distinct t.occasion_id, t.companion_id, t.group_id from tickets t left join occasions o on o.id = t.occasion_id where t.event_id = #{event.id} and o.date < now() and t.state in (2,3)"
          data = Ticket.connection.select_all(query)
          chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

          data.each do |d|

            tempid = ""
            (1..45).each { |i| tempid << chars[rand(chars.size-1)] }

            answer_form = AnswerForm.new do |a|
              a.id = tempid
              a.completed = true
              a.companion_id = d["companion_id"]
              a.occasion_id = d["occasion_id"]
              a.group_id = d["group_id"]
              a.questionnaire = questionnaire
            end

            puts "\tAnswer form"
            answer_form.save!

            puts "\tAnswers"
            questionnaire.questions.each do |question|
              answer = Answer.new do |a|
                a.question = question
                a.answer_form = answer_form

                case question.qtype
                when "QuestionText"
                  a.answer_text = "Test"
                when "QuestionMark"
                  a.answer_text = rand(4)
                when "QuestionBool"
                  a.answer_text = rand(2) == 0 ? "y" : "n"
                when "QuestionMchoice"
                  choices = {}
                  question.choice_csv.split(",").each { |c| choices[c] = c if rand(2) == 0 }
                  a.answer_text = choices
                end
              end

              answer.save!
            end
          end

        end

      end
    end
  end
end
