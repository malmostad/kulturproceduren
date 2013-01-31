require 'rubygems'
gem 'soap4r'
require(File.join(File.dirname(__FILE__), 'elit-kp-service', 'elit-kp.rb'))
require(File.join(File.dirname(__FILE__), 'elit-kp-service', 'elit-kpMappingRegistry.rb'))
require(File.join(File.dirname(__FILE__), 'elit-kp-service', 'elit-kpDriver.rb'))

require 'pp'

# Tasks for synchronizing with Elit
namespace :kp do

  desc "Synchronize all possible data with Elit"
  task(:elitsync) do
    Rake::Task["kp:elitsync:districts"].invoke
    Rake::Task["kp:elitsync:schools"].invoke
    Rake::Task["kp:elitsync:groups"].invoke
    Rake::Task["kp:elitsync:age_groups"].invoke
    Rake::Task["kp:elitsync:school_contacts"].invoke
    Rake::Task["kp:elitsync:group_contacts"].invoke
  end

  namespace :elitsync do

    def get_service
      service = KP::Elit::ElitKpPortType.new APP_CONFIG[:elit_kp_service_endpoint]
      service.wiredump_dev = STDERR if ENV["debug"]
      return service
    end

    desc "Synchronize districts"
    task(:districts => :environment) do
      puts "\n\nSynchronizing KP districts with Elit\n\n"
      service = get_service()

      elit_districts = service.getDistricts("")

      elit_districts.each do |elit_district|
        puts "District from Elit: #{elit_district.to_json}"
        local_district = District.find :first, :conditions => { :elit_id => elit_district.id.strip }

        if local_district
          puts "\tFound local district: #{local_district.attributes.to_json}"
        else
          puts "\tNo local district found, creating a new"
          local_district = District.new
          local_district.elit_id = elit_district.id.strip
        end

        local_district.name = elit_district.name
        if local_district.save
          puts "\tDistrict saved: #{local_district.attributes.to_json}"
        else
          puts "\tAn error occurred while saving the district: #{elit_district.name}"
          puts "\t#{local_district.errors.to_json}" if ENV["debug"]
        end

        puts " "
      end
    end

    desc "Synchronize schools"
    task(:schools => :environment) do
      puts "\n\nSynchronizing KP schools with Elit\n\n"
      service = get_service()

      districts = District.find :all, :conditions => "elit_id is not null"

      districts.each do |district|
        puts "\n\tSynchronizing district #{district.name}\n\n"

        elit_schools = service.getSchools(district.elit_id)
        elit_schools.each do |elit_school|
          puts "\tSchool from Elit: #{elit_school.to_json}"
          local_school = School.find :first, :conditions => { :elit_id => elit_school.id.strip }

          if local_school
            puts "\t\tFound local school: #{local_school.attributes.to_json}"

            local_school.name = elit_school.name

            if local_school.save
              puts "\t\tSchool saved: #{local_school.attributes.to_json}"
            else
              puts "\t\tAn error occurred while saving the school: #{elit_school.name}"
              puts "\t\t#{local_school.errors.to_json}"
            end
          else
            puts "\t\tNo local school found, creating a new"

            local_school = School.new
            local_school.elit_id = elit_school.id.strip
            local_school.district = district
            local_school.name = elit_school.name

            if local_school.save
              puts "\t\tSchool saved: #{local_school.attributes.to_json}"
            else
              puts "\t\tAn error occurred while saving the school: #{elit_school.name}"
              puts "\t\t#{local_school.errors.to_json}"
            end
          end


          puts " "
        end
      end
    end

    desc "Synchronize groups"
    task(:groups => :environment) do
      puts "\n\nSynchronizing KP groups with Elit\n\n"
      service = get_service()

      schools = School.find :all, :conditions => "elit_id is not null"

      schools.each do |school|
        puts "\n\tSynchronizing school #{school.name}\n\n"

        elit_groups = service.getGroups(school.elit_id)
        elit_groups.each do |elit_group|
          puts "\tGroup from Elit: #{elit_group.to_json}"
          local_group = Group.find :first, :conditions => { :elit_id => elit_group.id.strip }

          if local_group
            puts "\t\tFound local group: #{local_group.attributes.to_json}"
          else
            puts "\t\tNo local group found, creating a new"
            local_group = Group.new
            local_group.elit_id = elit_group.id.strip
            local_group.school = school
          end

          local_group.name = elit_group.name
          if local_group.save
            puts "\t\tGroup saved: #{local_group.attributes.to_json}"
          else
            puts "\t\tAn error occurred while saving the group: #{elit_group.name}"
            puts "\t\t#{local_group.errors.to_json}"
          end

          puts " "
        end
      end
    end

    desc "Synchronize age groups"
    task(:age_groups => :environment) do
      puts "\n\nSynchronizing KP age groups with Elit\n\n"
      service = get_service()

      groups = Group.find :all, :conditions => "elit_id is not null"

      groups.each do |group|
        puts "\n\tSynchronizing group #{group.name}"

        elit_age_groups = service.getAgeGroups(group.elit_id)

        group.age_groups.clear
        puts "\tClearing the group's current age groups\n\n"

        elit_age_groups.each do |elit_age_group|
          puts "\tAge group from Elit: #{elit_age_group.to_json}"
          puts "\t\tCreating local age group"
          local_age_group = AgeGroup.new do |ag|
            ag.group = group
            ag.age = elit_age_group.age
            ag.quantity = elit_age_group.amount
          end

          if local_age_group.save
            puts "\t\tAge group saved: #{local_age_group.attributes.to_json}"
          else
            puts "\t\tAn error occurred while saving the age group: #{elit_age_group.name}"
            puts "\t\t#{local_age_group.errors.to_json}"
          end

          puts " "
        end
      end
    end

    desc "Synchronize school contacts"
    task(:school_contacts => :environment) do
      puts "\n\nSynchronizing KP school contacts with Elit\n\n"
      service = get_service()

      schools = School.find :all, :conditions => "elit_id is not null"

      schools.each do |school|
        puts "\n\tSynchronizing school #{school.name}\n\n"

        elit_contacts = service.getSchoolContacts(school.elit_id)
        if elit_contacts.empty?
          puts "\t\tNo contacts for school in Elit"
        else
          if school.contacts.blank?
            local_contacts = []
            puts "\t\tNo current local contacts"
          else
            local_contacts = school.contacts.split(",").collect { |c| c.strip }
            puts "\t\tCurrent local contacts: #{local_contacts.join(",")}"
          end

          elit_contacts = elit_contacts.collect { |c| c.email.strip }
          elit_contacts.delete_if { |c| c !~ /[^@]+@[^@]+/ }
          puts "\t\tContacts from Elit: #{elit_contacts.join(",")}"

          merged_contacts = local_contacts + elit_contacts
          merged_contacts.uniq!

          school.contacts = merged_contacts.join(",")

          if school.save
            puts "\t\tSchool contacts saved: #{school.contacts}"
          else
            puts "\t\tAn error occurred while saving the school contacts: #{school.contacts}"
            puts "\t\t#{school.errors.to_json}"
          end

          puts " "
        end
      end
    end

    desc "Synchronize group contacts"
    task(:group_contacts => :environment) do
      puts "\n\nSynchronizing KP group contacts with Elit\n\n"
      service = get_service()

      groups = Group.find :all, :conditions => "elit_id is not null"

      groups.each do |group|
        puts "\n\tSynchronizing group #{group.name}\n\n"

        elit_contacts = service.getGroupContacts(group.elit_id)
        if elit_contacts.empty?
          puts "\t\tNo contacts for group in Elit"
        else
          if group.contacts.blank?
            local_contacts = []
            puts "\t\tNo current local contacts"
          else
            local_contacts = group.contacts.split(",").collect { |c| c.strip }
            puts "\t\tCurrent local contacts: #{local_contacts.join(",")}"
          end

          elit_contacts = elit_contacts.collect { |c| c.email.strip }
          elit_contacts.delete_if { |c| c !~ /[^@]+@[^@]+/ }
          puts "\t\tContacts from Elit: #{elit_contacts.join(",")}"

          merged_contacts = local_contacts + elit_contacts
          merged_contacts.uniq!

          group.contacts = merged_contacts.join(",")

          if group.save
            puts "\t\tGroup contacts saved: #{group.contacts}"
          else
            puts "\t\tAn error occurred while saving the group contacts: #{group.contacts}"
            puts "\t\t#{group.errors.to_json}"
          end

          puts " "
        end
      end
    end
  end
end
