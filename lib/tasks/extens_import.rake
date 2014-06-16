require "csv"
require "kp/import/district_importer"
require "kp/import/school_importer"
require "kp/import/group_importer"
require "kp/import/alternative_group_importer"
require "kp/import/age_group_importer"
require "kp/import/school_contact_importer"
require "kp/import/group_contact_importer"

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
          puts "Deleted: #{result[:deleted]}" if result[:deleted]
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
        csv_separator = ENV["csv_separator"] || "\t"

        school_type = SchoolType.find(ENV["school_type_id"])
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)

        puts "Importing groups from #{ENV["file"]}"

        begin
          import!(KP::Import::GroupImporter.new(csv, school_type.id), csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
        end
      end

      desc "Import groups (alternative file format, from age group file)"
      task(alternative_groups: :environment) do
        csv_separator = ENV["csv_separator"] || "\t"

        school_type = SchoolType.find(ENV["school_type_id"])
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)

        puts "Importing groups from #{ENV["file"]}"

        begin
          import!(KP::Import::AlternativeGroupImporter.new(csv, school_type.id), csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
        end
      end

      desc "Import age groups"
      task(age_groups: :environment) do
        csv_separator = ENV["csv_separator"] || "\t"

        school_type = SchoolType.find(ENV["school_type_id"])
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)

        puts "Importing age groups from #{ENV["file"]}"

        begin
          import!(KP::Import::AgeGroupImporter.new(csv, school_type.id), csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
        end
      end

      desc "Import school contacts"
      task(school_contacts: :environment) do
        csv_separator = ENV["csv_separator"] || "\t"

        school_type = SchoolType.find(ENV["school_type_id"])
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)

        puts "Importing school contacts from #{ENV["file"]}"

        begin
          import!(KP::Import::SchoolContactImporter.new(csv, school_type.id), csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
        end
      end

      desc "Import group contacts"
      task(group_contacts: :environment) do
        csv_separator = ENV["csv_separator"] || "\t"

        school_type = SchoolType.find(ENV["school_type_id"])
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)

        puts "Importing group contacts from #{ENV["file"]}"

        begin
          import!(KP::Import::GroupContactImporter.new(csv, school_type.id), csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
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
