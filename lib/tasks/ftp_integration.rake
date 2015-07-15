require "csv"
require "active_support"
require "kk/ftp_import/district_importer"
require "kk/ftp_import/school_importer"
require "kk/ftp_import/group_importer"
require "kk/ftp_import/alternative_group_importer"
require "kk/ftp_import/age_group_importer"
require "kk/ftp_import/school_contact_importer"
require "kk/ftp_import/group_contact_importer"


namespace :kk do
	namespace :extens do
    desc "Import of extens data from file directory"
    task(:ftp_import) do
      Rake::Task["kk:extens:ftp_import:import_files"].invoke
    end

    	namespace :ftp_import do
    		ENV["ALLFILES"] = "false"
    		school_type = 1
    		fileDate = Date.yesterday.to_s
    		subject = "Daglig överföring från Extens"
    		body = "Den dagliga överföringen från Extens misslyckades för filer skickade " + fileDate
    		filenames = ["forskola_utbildningsomraden", "forskolor.tsv", "forskolor_antal_barn.tsv"].to_set

    		task(checkfiles: :environment) do
        		dir = Dir::glob(APP_CONFIG[:ftp_import_directory]+"*")
        		if filenames.subset?(dir.to_set)
        			ENV["ALLFILES"] = "true"
        		else
        			InformationMailer.custom_email(APP_CONFIG[:mailers][:existens_error_reporting], subject, body).deliver
        		end
      		end

      		desc "Import pre-schools from Extens"
      		task(pre_schools: :environment) do
      			ENV["file"] = "forskola_utbildningsomraden.tsv"
        		do_import("pre school districts", KK::FTP_Import::DistrictImporter.new(CSV.open("forskola_utbildningsomraden.tsv"), school_type.id))
        		ENV["file"] = "forskolor.tsv"
        		do_import("pre schools", KK::FTP_Import::SchoolImporter.new(CSV.open("forskolor.tsv"), school_type.id))
        		ENV["file"] = "forskolor_grupper.tsv"
        		do_import("pre school classes", KK::FTP_Import::GroupImporter.new(CSV.open("forskolor_grupper.tsv"), school_type.id))
        		ENV["file"] = "forskolor_antal_barn.tsv"
        		do_import("pre school number of children", KK::FTP_Import::AgeGroupImporter.new(CSV.open("forskolor_antal_barn.tsv"), school_type.id))
        		ENV["file"] = "forskolor_kontakter.tsv"
        		do_import("pre school contacts", KK::FTP_Import::SchoolContactImporter.new(CSV.open("forskolor_kontakter.tsv"), school_type.id))
      		end

      		desc "Import schools"
     		task(schools: :environment) do
     			ENV["file"] = "grundskola_utbildningsomraden.tsv"
        		do_import("schools districts", KK::FTP_Import::DistrictImporter.new(CSV.open("grundskola_utbildningsomraden.tsv"), school_type.id))
        		ENV["file"] = "grundskolor.tsv"
        		do_import("schools", KK::FTP_Import::SchoolImporter.new(CSV.open("grundskolor.tsv"), school_type.id))
        		ENV["file"] = "grundskolor_klasser.tsv"
        		do_import("school classes", KK::FTP_Import::GroupImporter.new(CSV.open("grundskolor_klasser.tsv"), school_type.id))
        		ENV["file"] = "grundskolor_antal_barn.tsv"
        		do_import("school number of children", KK::FTP_Import::AgeGroupImporter.new(CSV.open("grundskolor_antal_barn.tsv"), school_type.id))
        		ENV["file"] = "grundskolor_rektorer.tsv"
        		do_import("school headmasters", KK::FTP_Import::SchoolContactImporter.new(CSV.open("grundskolor_rektorer.tsv"), school_type.id))
        		ENV["file"] = "grundskolor_klassforestandare.tsv"
        		do_import("school class contacts", KK::FTP_Import::GroupContactImporter.new(CSV.open("grundskolor_klassforestandare.tsv"), school_type.id))
      		end
      
      		desc "Import all files in ftp directory"
      		task(import_files: :environment) do
      			Rake::Task["kk:extens:ftp_import:checkfiles"].invoke
      			Rake::Task["kk:extens:ftp_import:pre_schools"].invoke
      			Rake::Task["kk:extens:ftp_import:schools"].invoke
      		end

      		private
      		def do_import(subject, importer)
         		puts "Importing #{subject} from #{ENV["file"]}"
        		begin
        			result = importer.import!
        		rescue KP::Import::ParseError => e
          			puts "Found errors when importing:\n#{e.message}"
        		end
      		end
    	end
  	end
end