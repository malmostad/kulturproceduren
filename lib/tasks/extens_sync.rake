# -*- coding: utf-8 -*-
require 'pp'

namespace :kp do
  namespace :extens do
    desc "Synchronize all possible data with Extens"
    task(:sync) do
      Rake::Task["kp:extens:sync:districts"].invoke
    end

    namespace :sync do

      def get_connection
        # Use User for establishing connections to the extens database since it is
        # not used in this synchronization
        User.establish_connection(:extens).connection
      end
      def sanitize_sql(a)
        User.send(:sanitize_sql_array, a)
      end

      desc "Synchronize districts with Extens"
      task(districts: :environment) do
        puts "\n\nSynchronizing KP districts with Extens\n\n"
        conn = get_connection()
        extens_districts = conn.select_all('select stadsdel_guid, namn from vvkultstadsdel')

        extens_districts.each do |extens_district|
          puts "District from Extens:\t\t\t\t#{extens_district['stadsdel_guid']}\t#{extens_district['namn']}"
          local_district = District.find :first, conditions: { extens_id: extens_district['stadsdel_guid'] }

          if local_district
            puts "\tFound local district:\t\t#{local_district.id}\t#{local_district.extens_id}\t#{local_district.name}"
          else
            puts "\tNo local district found, creating a new"
            local_district = District.new
            local_district.extens_id = extens_district['stadsdel_guid']
          end

          local_district.name = extens_district['namn']

          if local_district.save
            puts "\tDistrict saved:\t\t\t#{local_district.id}\t#{local_district.extens_id}\t#{local_district.name}"
          else
            puts "\tAn error occurred while saving the district:\t#{local_district.id}\t#{local_district.name}"
            puts "\t#{local_district.errors.to_yaml}"
          end

          puts " "
        end
      end

      desc "Synchronize schools"
      task(schools: :environment) do
        puts "\n\nSynchronizing KP schools with Extens\n\n"
        conn = get_connection()

        districts = District.find :all, conditions: "extens_id is not null"

        districts.each do |district|
          puts "\n\tSynchronizing district #{district.name}\n\n"

          extens_schools = conn.select_all(sanitize_sql(['select * from vvkultskolor where stadsdel_guid = ?', district.extens_id]));
          extens_schools.each do |extens_school|
            sync_school(district, "skola-#{extens_school['enhet_guid']}", extens_school['namn'])
          end

          extens_schools = conn.select_all(sanitize_sql(['select * from vvkultforskolor where stadsdel_guid = ?', district.extens_id]));
          extens_schools.each do |extens_school|
            sync_school(district, "forskola-#{extens_school['enhet_guid']}", extens_school['namn'])
          end
        end
      end

      desc "Synchronize school contacts"
      task(school_contacts: :environment) do
        puts "\n\nSynchronizing KP school contacts with Extens\n\n"
        conn = get_connection()

        schools = School.find :all, conditions: "extens_id is not null"

        schools.each do |school|
          # Only contacts on schools, not preschools
          if school.extens_id =~ /^skola-/
            puts "\n\tSynchronizing school #{school.name}\n\n"

            extens_contacts = conn.select_all(sanitize_sql([
              'select rektor_email as email from vvkultrektorer where enhet_guid = ?',
              school.extens_id.gsub(/^skola-/, '')
            ]))

            if extens_contacts.empty?
              puts "\t\tNo contacts for school in Extens"
            else
              if school.contacts.blank?
                local_contacts = []
              else
                local_contacts = school.contacts.split(",")
              end

              school.contacts = merge_contacts(local_contacts, extens_contacts).join(",")

              if school.save
                puts "\t\tSchool contacts saved:\t#{school.contacts}"
              else
                puts "\t\tAn error occurred while saving the school contacts: #{school.contacts}"
                puts "\t\t#{school.errors.to_json}"
              end

              puts " "
            end
          else
            next
          end
        end
      end

      desc "Synchronize groups"
      task(groups: :environment) do
        puts "\n\nSynchronizing KP groups with Extens\n\n"
        conn = get_connection()

        schools = School.find :all, conditions: "extens_id is not null"

        schools.each do |school|
          puts "\n\tSynchronizing school #{school.name}\n\n"

          if school.extens_id =~ /^skola-/
            extens_groups = conn.select_all(sanitize_sql([
              'select distinct klass_guid as extens_id, klass as name from vvkultantalbarn where enhet_guid = ?',
              school.extens_id.gsub(/^skola-/, '')
            ]))
            prefix = "skolgrupp-"
          elsif school.extens_id =~ /^forskola-/
            extens_groups = conn.select_all(sanitize_sql([
              'select distinct avdelning_guid as extens_id, namn as name from vvkultantalbarnfsk where enhet_guid = ?',
              school.extens_id.gsub(/^forskola-/, '')
            ]))
            prefix = "forskolgrupp-"
          else
            next
          end

          extens_groups.each do |extens_group|
            puts "\tGroup from Extens:\t\t\t#{prefix}#{extens_group['extens_id']}\t#{extens_group['name']}"
            local_group = Group.find :first, conditions: { extens_id: "#{prefix}#{extens_group['extens_id'].strip}" }

            if local_group
              puts "\t\tFound local group:\t#{local_group.id}\t#{local_group.extens_id}\t#{local_group.name}"
            else
              puts "\t\tNo local group found, creating a new"
              local_group = Group.new
              local_group.extens_id = "#{prefix}#{extens_group['extens_id'].strip}"
              local_group.school = school
            end

            local_group.name = extens_group['name']

            if local_group.save
              puts "\t\tGroup saved:\t\t#{local_group.id}\t#{local_group.extens_id}\t#{local_group.name}"
            else
              puts "\t\tAn error occurred while saving the group:\t#{local_group.id}\t#{local_group.extens_id}\t#{local_group.name}"
              puts "\t\t#{local_group.errors.to_yaml}"
            end

            puts " "
          end
        end
      end

      desc "Synchronize group contacts"
      task(group_contacts: :environment) do
        puts "\n\nSynchronizing KP group contacts with Extens\n\n"
        conn = get_connection()

        groups = Group.find :all, conditions: "extens_id is not null"

        groups.each do |group|
          puts "\n\tSynchronizing group #{group.name}\n\n"

          if group.extens_id =~ /^skolgrupp-/
            extens_contacts = conn.select_all(sanitize_sql([
              'select klass_email as email from vvkultklassforestandare where klass_guid = ?',
              group.extens_id.gsub(/^skolgrupp-/, '')
            ]))
          elsif group.extens_id =~ /^forskolgrupp-/
            extens_contacts = conn.select_all(sanitize_sql([
              'select forskola_email as email from vvkultforskoloremail where avdelning_guid = ?',
              group.extens_id.gsub(/^forskolgrupp-/, '')
            ]))
          else
            next
          end

          if extens_contacts.empty?
            puts "\t\tNo contacts for group in Extens"
          else
            if group.contacts.blank?
              local_contacts = []
            else
              local_contacts = group.contacts.split(",")
            end

            group.contacts = merge_contacts(local_contacts, extens_contacts).join(",")

            if group.save
              puts "\t\tGroup contacts saved:\t#{group.contacts}"
            else
              puts "\t\tAn error occurred while saving the group contacts:\t#{group.contacts}"
              puts "\t\t#{group.errors.to_yaml}"
            end

            puts " "
          end
        end
      end

      desc "Synchronize age groups"
      task(age_groups: :environment) do
        puts "\n\nSynchronizing KP age groups with Extens\n\n"
        conn = get_connection()

        groups = Group.find :all, conditions: "extens_id is not null"

        # Calculate the age based on the current school year
        base_year = (Date.today - 6.months).year

        groups.each do |group|
          puts "\n\tSynchronizing group #{group.name}"

          if group.extens_id =~ /^skolgrupp-/
            extens_age_groups = conn.select_all(sanitize_sql([
              'select antal_elever as num, fodelsear as birth_year from vvkultantalbarn where klass_guid = ?',
              group.extens_id.gsub(/^skolgrupp-/, '')
            ]))
          elsif group.extens_id =~ /^forskolgrupp-/
            extens_age_groups = conn.select_all(sanitize_sql([
              'select antal_barn as num, fodelsear as birth_year from vvkultantalbarnfsk where avdelning_guid = ?',
              group.extens_id.gsub(/^forskolgrupp-/, '')
            ]))
          else
            next
          end

          group.age_groups.clear
          puts "\t\tClearing the group's current age groups\n\n"

          extens_age_groups.each do |extens_age_group|
            puts "\t\tAge group from Extens:\t\t#{extens_age_group['birth_year']}\t#{extens_age_group['num']}"
            puts "\t\tCreating local age group"
            local_age_group = AgeGroup.new do |ag|
              ag.group = group
              ag.age = base_year - extens_age_group['birth_year'].to_i
              ag.quantity = extens_age_group['num'].to_i
            end

            if local_age_group.save
              puts "\t\tAge group saved:\t\t#{local_age_group.age}\t#{local_age_group.quantity}"
            else
              puts "\t\tAn error occurred while saving the age group:\t#{local_age_group.id}"
              puts "\t\t#{local_age_group.errors.to_yaml}"
            end

            puts " "
          end
        end
      end


      def sync_school(district, extens_id, extens_name)
        puts "\tSchool from Extens:\t\t\t#{extens_id}\t#{extens_name}"
        local_school = School.find :first, conditions: { extens_id: extens_id }

        if local_school
          puts "\t\tFound local school:\t#{local_school.id}\t#{local_school.extens_id}\t#{local_school.name}"

          local_school.name = extens_name

          if local_school.save
            puts "\t\tSchool saved:\t\t#{local_school.id}\t#{local_school.extens_id}\t#{local_school.name}"
          else
            puts "\t\tAn error occurred while saving the school:\t#{local_school.id}\t#{local_school.name}"
            puts "\t\t#{local_school.errors.to_yaml}"
          end
        else
          puts "\t\tNo local school found, creating a new"

          local_school = School.new
          local_school.extens_id = extens_id
          local_school.district = district
          local_school.name = extens_name

          if local_school.save
            puts "\t\tSchool saved:\t\t#{local_school.id}\t#{local_school.extens_id}\t#{local_school.name}"
          else
            puts "\t\tAn error occurred while saving the school:\t\t#{local_school.id}\t#{local_school.name}"
            puts "\t\t#{local_school.errors.to_yaml}"
          end
        end

        puts " "
      end

      def merge_contacts(local, remote)
        local = local.collect { |c| c.try(:strip) }.compact
        local.delete_if { |c| c !~ /[^@]+@[^@]+/ }

        puts "\t\tLocal contacts:\t\t#{local.join(",")}"

        remote = remote.collect { |c| c['email'].try(:strip) }.compact
        remote.delete_if { |c| c !~ /[^@]+@[^@]+/ }

        puts "\t\tContacts from Extens:\t#{remote.join(",")}"

        merged = local + remote
        merged.uniq!

        return merged
      end

    end
  end
end
