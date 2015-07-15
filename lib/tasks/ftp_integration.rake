require "csv"
require "active_support"
require "kk/ftp_import/pre_schools"
require "kk/ftp_import/schools"
require "kk/ftp_import/high_schools"

namespace :kk do
	namespace :extens do
    desc "Import of extens data from file directory"
    task(:ftp_import) do
      Rake::Task["kk:extens:ftp_import:import_files"].invoke
    end

    	namespace :ftp_import do
    		ENV["ALLFILES"] = "false"
    		csv_separator = ENV["csv_separator"] || "\t"
    		school_type = 1
    		fileDate = Date.yesterday.to_s
    		subject = "Daglig överföring från Extens"
    		body = "Den dagliga överföringen från Extens misslyckades för filer skickade " + fileDate
    		filenames = ["forskola_utbildningsomraden", "forskolor.tsv", "forskolor_antal_barn.tsv"].to_set

    		task(checkfiles: :environment) do
        		dir = Dir::glob(APP_CONFIG[:ftp_import_directory]+"*")
        		if filenames.subset?(dir.to_set)
        			ENV["ALLFILES"] = "true"
        			puts "true"
        		else
        			InformationMailer.custom_email(APP_CONFIG[:mailers][:existens_error_reporting], subject, body).deliver
        			puts "false"
        		end
      		end

      		desc "Import pre-schools from Extens"
      		task(pre_schools: :environment) do
        		csv, school_prefix, group_prefix = create_importer_arguments
        		do_import("pre_schools", KK::FTP_Import::Pre_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("pre_schools", KK::FTP_Import::Pre_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("pre_schools", KK::FTP_Import::Pre_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("pre_schools", KK::FTP_Import::Pre_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("pre_schools", KK::FTP_Import::Pre_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
      		end

      		desc "Import schools"
     		task(schools: :environment) do
        		csv, school_prefix, group_prefix = create_importer_arguments
        		do_import("schools", KK::FTP_Import::SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("schools", KK::FTP_Import::SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("schools", KK::FTP_Import::SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("schools", KK::FTP_Import::SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("schools", KK::FTP_Import::SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("schools", KK::FTP_Import::SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
      		end

      		desc "Import High schools"
      		task(high_schools: :environment) do
        		csv, school_prefix, group_prefix = create_importer_arguments
        		do_import("high_schools", KK::FTP_Import::High_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("high_schools", KK::FTP_Import::High_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("high_schools", KK::FTP_Import::High_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("high_schools", KK::FTP_Import::High_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("high_schools", KK::FTP_Import::High_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
        		do_import("high_schools", KK::FTP_Import::High_SchoolImporter.new(csv, school_type.id, school_prefix, group_prefix), csv_separator)
      		end
      
      		desc "Import all files in ftp directory"
      		task(import_files: :environment) do
      			Rake::Task["kk:extens:ftp_import:checkfiles"].invoke
      			Rake::Task["kk:extens:ftp_import:pre_schools"].invoke
      			Rake::Task["kk:extens:ftp_import:schools"].invoke
      			Rake::Task["kk:extens:ftp_import:high_schools"].invoke
      		end
    	end
  	end
end