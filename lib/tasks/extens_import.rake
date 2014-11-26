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
        csv, csv_separator, school_type = create_importer_arguments
        do_import("districts", KP::Import::DistrictImporter.new(csv, school_type.id), csv_separator)
      end

      desc "Import schools from Extens"
      task(schools: :environment) do
        csv, csv_separator, school_type = create_importer_arguments
        do_import("schools", KP::Import::SchoolImporter.new(csv, school_type.id), csv_separator)
      end

      desc "Import groups"
      task(groups: :environment) do
        csv, csv_separator, school_type = create_importer_arguments
        do_import("groups", KP::Import::GroupImporter.new(csv, school_type.id), csv_separator)
      end

      desc "Import groups (alternative file format, from age group file)"
      task(alternative_groups: :environment) do
        csv, csv_separator, school_type = create_importer_arguments
        do_import("groups", KP::Import::AlternativeGroupImporter.new(csv, school_type.id), csv_separator)
      end

      desc "Import age groups"
      task(age_groups: :environment) do
        csv, csv_separator, school_type = create_importer_arguments
        do_import("age groups", KP::Import::AgeGroupImporter.new(csv, school_type.id), csv_separator)
      end

      desc "Import school contacts"
      task(school_contacts: :environment) do
        csv, csv_separator, school_type = create_importer_arguments
        do_import("school contacts", KP::Import::SchoolContactImporter.new(csv, school_type.id), csv_separator)
      end

      desc "Import group contacts"
      task(group_contacts: :environment) do
        csv, csv_separator, school_type = create_importer_arguments
        do_import("group contacts", KP::Import::GroupContactImporter.new(csv, school_type.id), csv_separator)
      end

      desc "Prepare old group objects for fresh import by setting active=false and adding suffix to names"
      task(do_prepare_groups: :environment) do
        suffix = ENV["suffix"] || ""
        suffix = " Kentor" if suffix.empty?
        puts "Do prepare of group objects with suffix \"#{suffix}\""
        Group.where(active: true).find_each do |group|
          group.update_attribute(:name, group.name+=suffix)
          group.update_attribute(:active, false)
        end
      end

      desc "Undo prepare old group objects for fresh import by setting active=true and removing suffix from names"
      task(undo_prepare_groups: :environment) do
        suffix = ENV["suffix"] || ""
        suffix = " Kentor" if suffix.empty?
        puts "Undo prepare of group objects with suffix \"#{suffix}\""
        Group.where(active: false).find_each do |group|
          group.update_attribute(:active, true) if group.name.end_with?(suffix)
          group.update_attribute(:name, group.name.chomp(suffix))
        end
      end

      private

      def create_importer_arguments
        csv_separator = ENV["csv_separator"] || "\t"
        csv = CSV.open(ENV["file"], "r", col_sep: csv_separator)
        school_type = SchoolType.find(ENV["school_type_id"])

        return csv, csv_separator, school_type
      end

      def do_import(subject, importer, csv_separator)
         puts "Importing #{subject} from #{ENV["file"]}"

        begin
          import!(importer, csv_separator)
        rescue KP::Import::ParseError => e
          puts "Found errors when importing:\n#{e.message}"
        end
      end

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
