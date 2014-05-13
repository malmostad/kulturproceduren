require "csv"
require "kp/import/district_importer"
require "kp/import/school_importer"

namespace :kp do
  namespace :extens do
    desc "Initial import of extens data from data dump"
    task(:import) do
      Rake::Task["kp:extens:import:districts"].invoke
    end

    namespace :import do

      def import!(importer, csv_separator)
        if importer.valid?
          print "No invalid rows found, importing..."
          result = importer.import!
          puts " done!"

          puts "New: #{result[:new]}"
          puts "Updated: #{result[:updated]}"
          puts "Unchanged: #{result[:unchanged]}"
        else
          puts "Invalid rows found:\n"
          importer.invalid_rows.each do |row|
            puts row.join(csv_separator)
          end
          puts "Aborting..."
        end
      end

      desc "Import districts from Extens"
      task(districts: :environment) do
        csv_separator = ENV["csv_separator"] || "\t"

        school_type = SchoolType.find(ENV["school_type_id"])
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)

        puts "Importing districts from #{ENV["file"]}"

        begin
          import!(KP::Import::DistrictImporter.new(csv, school_type.id), csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
        end
      end

      desc "Import schools from Extens"
      task(schools: :environment) do
        csv_separator = ENV["csv_separator"] || "\t"

        school_type = SchoolType.find(ENV["school_type_id"])
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)

        puts "Importing schools from #{ENV["file"]}"

        begin
          import!(KP::Import::SchoolImporter.new(csv, school_type.id), csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
        end
      end

      desc "Import groups"
      task(groups: :environment) do
        raise "Missing school_prefix" unless ENV["school_prefix"]
        raise "Missing group_prefix" unless ENV["group_prefix"]
        puts "\n"

        verify_extens_csv_file(ENV["from"], ENV["csv_sep"], 6)

        CSV.open(ENV["from"], "r", ENV["csv_sep"][0]) do |row|
          guid, school_guid, school_name, name = row
          guid = "#{ENV["group_prefix"]}-#{guid}"
          school_guid = "#{ENV["school_prefix"]}-#{school_guid}"

          puts "Processing #{name}\t#{guid}"

          group = Group.first(conditions: { extens_id: guid })

          if !group
            puts "\tGroup with ID not found, creating new"

            school = School.first(conditions: { extens_id: school_guid })

            if !school
              puts "\tUnknown school #{school_guid}, skipping"
              next
            end

            group = Group.new
            group.name = name
            group.extens_id = guid
            group.school = school
            group.active = true
            group.save!
          else
            puts "\tGroup with ID already exists: #{group.name}, updating name"
            group.name = name
            group.active = true
            group.save!
          end

          puts "\n"
        end
      end

      desc "Import age groups"
      task(age_groups: :environment) do
        raise "Missing group_prefix" unless ENV["group_prefix"]
        puts "\n"

        verify_extens_csv_file(ENV["from"], ENV["csv_sep"], 6)

        # Calculate the age based on the current school year
        base_year = (Date.today - 6.months).year

        cleared_age_groups = []

        CSV.open(ENV["from"], "r", ENV["csv_sep"][0]) do |row|
          school_guid, group_guid, group_name, school_name, amount, birth_year = row
          group_guid = "#{ENV["group_prefix"]}-#{group_guid}"

          puts "Processing #{birth_year} - #{group_name}\t#{group_guid}"

          group = Group.first(conditions: { extens_id: group_guid })

          if !group
            puts "\tUnknown group #{group_guid}, skipping"
            next
          end

          if !cleared_age_groups.include?(group.id)
            puts "\tClearing age groups for #{group.id}"
            cleared_age_groups << group.id
            group.age_groups.clear
          end

          puts "\tCreating age group"

          age_group = AgeGroup.new
          age_group.group = group
          age_group.age = base_year - birth_year.to_i
          age_group.quantity = amount
          age_group.save!

          puts "\n"
        end
      end

      desc "Import preschool data - both groups and amounts"
      task(preschool: :environment) do
        raise "Missing school_prefix" unless ENV["school_prefix"]
        raise "Missing group_prefix" unless ENV["group_prefix"]
        puts "\n"

        verify_extens_csv_file(ENV["from"], ENV["csv_sep"], 6)

        # Calculate the age based on the current school year
        base_year = (Date.today - 6.months).year

        cleared_age_groups = []

        CSV.open(ENV["from"], "r", ENV["csv_sep"][0]) do |row|
          school_guid, group_guid, group_name, school_name, amount, birth_year = row
          group_guid = "#{ENV["group_prefix"]}-#{group_guid}"
          school_guid = "#{ENV["school_prefix"]}-#{school_guid}"

          puts "Processing #{birth_year} - #{group_name}\t#{group_guid}"

          group = Group.first(conditions: { extens_id: group_guid })

          if !group
            school = School.first(conditions: { extens_id: school_guid })

            if !school
              puts "\tUnknown school #{school_guid}, skipping"
              next
            end

            puts "\tUnknown group #{group_guid}, creating new"

            group = Group.new
            group.name = group_name
            group.extens_id = group_guid
            group.school = school
            group.active = true
            group.save!
          else
            puts "\tFound group #{group_guid}, updating name"
            group.name = group_name
            group.active = true
            group.save!
          end

          if !cleared_age_groups.include?(group.id)
            puts "\tClearing age groups for #{group.id}"
            cleared_age_groups << group.id
            group.age_groups.clear
          end

          puts "\tCreating age group"

          age_group = AgeGroup.new
          age_group.group = group
          age_group.age = base_year - birth_year.to_i
          age_group.quantity = amount
          age_group.save!

          puts "\n"
        end
      end

      desc "Import school contacts"
      task(school_contacts: :environment) do
        raise "Missing school_prefix" unless ENV["school_prefix"]
        puts "\n"

        verify_extens_csv_file(ENV["from"], ENV["csv_sep"], 3)

        CSV.open(ENV["from"], "r", ENV["csv_sep"][0]) do |row|
          school_guid, school_name, emails = row
          school_guid = "#{ENV["school_prefix"]}-#{school_guid}"

          emails = nil if emails == "(null)"

          puts "Processing #{school_guid}"

          school = School.first(conditions: { extens_id: school_guid })
          next unless school

          school.contacts = merge_extens_contacts(school.contacts || "", emails || "")
          school.save!
        end

      end

      desc "Import school class contacts"
      task(school_class_contacts: :environment) do
        raise "Missing group_prefix" unless ENV["group_prefix"]
        puts "\n"

        verify_extens_csv_file(ENV["from"], ENV["csv_sep"], 4)

        CSV.open(ENV["from"], "r", ENV["csv_sep"][0]) do |row|
          group_guid, school_guid, group_name, emails = row
          group_guid = "#{ENV["group_prefix"]}-#{group_guid}"

          emails = nil if emails == "(null)"

          puts "Processing #{group_guid}"

          group = Group.first(conditions: { extens_id: group_guid })

          next unless group

          group.contacts = merge_extens_contacts(group.contacts || "", emails || "")
          group.save!
        end

      end


      private

      def verify_extens_csv_file(file, csv_sep, num_elements)
        errors = {}
        rownum = 1
        CSV.open(file, "r", csv_sep[0]) do |row|
          errors[rownum] = row.join(csv_sep) if row.length != num_elements
          rownum += 1
        end

        if !errors.blank?
          raise "Errors in CSV file:\n#{errors.to_yaml}"
        end
      end

      def merge_extens_contacts(local, remote)
        local = local.split(",").collect { |c| c.try(:strip) }.compact
        local.delete_if { |c| c !~ /[^@]+@[^@]+/ }

        puts "\t\tLocal contacts:\t\t#{local.join(",")}"

        remote = remote.split(",").collect { |c| c.try(:strip) }.compact
        remote.delete_if { |c| c !~ /[^@]+@[^@]+/ }

        puts "\t\tContacts from Extens:\t#{remote.join(",")}"

        merged = local + remote
        merged.uniq!

        return merged.join(",")
      end

    end
  end
end
