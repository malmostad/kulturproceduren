require "csv"
require "active_support"
require "fileutils"
require "kk/ftp_import/import_deleter"
require "kk/ftp_import/district_importer"
require "kk/ftp_import/school_importer"
require "kk/ftp_import/group_importer"
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
			csv_separator = ENV["csv_separator"] || "\t"
			school_type_id = 1
			fileDate = Date.yesterday.to_s
			subject = "Daglig överföring från Extens"
			body = "Den dagliga överföringen från Extens misslyckades för filer skickade " + fileDate

			desc "Check files..."
			task(checkfiles: :environment) do
				dir = Dir::glob(APP_CONFIG[:ftp_import_directory]+"*").grep(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/)
				if !dir.empty?
					ENV["ALLFILES"] = "true"
				else
					#InformationMailer.custom_email(APP_CONFIG[:mailers][:existens_error_reporting], subject, body).deliver
				end
			end

			desc "Import pre-schools from Extens"
			task(pre_schools: :environment) do
				encoding = 'utf-8'
				all_files = Dir::glob(APP_CONFIG[:ftp_import_directory]+"*").map {|p| File.basename p}.grep(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/)

				#PreSchool district is fetched from the same file as the actual pre-schools
				all_files.grep(/^forskolor_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("pre school districts", KK::FTP_Import::PreSchoolDistrictImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				# all_files.grep(/^forskoleomraden_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
				# 	ENV["file"] = file_name
				# 	do_import("pre school districts", KK::FTP_Import::PreSchoolDistrictImporterNew.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				# end

				all_files.grep(/^forskolor_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("pre schools", KK::FTP_Import::PreSchoolImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				all_files.grep(/^forskolor_grupper_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("pre school classes", KK::FTP_Import::GroupImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				all_files.grep(/^forskolor_antal_barn_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("pre school number of children", KK::FTP_Import::AgeGroupImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				all_files.grep(/^forskolor_kontakter_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("pre school contacts", KK::FTP_Import::PreSchoolContactImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end
			end

			desc "Import schools"
			task(schools: :environment) do
				encoding = 'utf-8'
				all_files = Dir::glob(APP_CONFIG[:ftp_import_directory]+"*").map {|p| File.basename p}.grep(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/)

				all_files.grep(/^utbildningsomraden_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("schools districts", KK::FTP_Import::DistrictImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				all_files.grep(/^skolor_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("schools", KK::FTP_Import::SchoolImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				all_files.grep(/^klasser_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("school classes", KK::FTP_Import::GroupImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				all_files.grep(/^antal_barn_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("school number of children", KK::FTP_Import::AgeGroupImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end

				all_files.grep(/^klassforestandare_[0-9]{4}\-[0-9]{2}\-[0-9]{2}.tsv/).sort.each do |file_name|
					ENV["file"] = file_name
					do_import("school class contacts", KK::FTP_Import::GroupContactImporter.new(CSV.open(APP_CONFIG[:ftp_import_directory]+file_name, "r", col_sep: csv_separator, encoding: encoding), school_type_id))
				end
			end

			desc "Moves files to archive"
			task(move_files: :environment) do
				dir = Dir::glob(APP_CONFIG[:ftp_import_directory]+"*.tsv")
				FileUtils.mv(dir, APP_CONFIG[:ftp_import_archive])
			end

			desc "Sets all extens districts, schools and groups to be deleted."
			task(mark_for_delete: :environment) do
				KK::FTP_Import::ImportDeleter.new().mark_for_delete()
			end

			desc "Deletes all marked records"
			task(delete_marked: :environment) do
				#KK::FTP_Import::ImportDeleter.new().delete_marked()
			end

			desc "Import all files in ftp directory"
			task(import_files: :environment) do
				Rake::Task["kk:extens:ftp_import:checkfiles"].invoke
				Rake::Task["kk:extens:ftp_import:mark_for_delete"].invoke
				Rake::Task["kk:extens:ftp_import:pre_schools"].invoke
				Rake::Task["kk:extens:ftp_import:schools"].invoke
				Rake::Task["kk:extens:ftp_import:move_files"].invoke
				Rake::Task["kk:extens:ftp_import:delete_marked"].invoke
			end

			private
			def do_import(subject, importer)
				puts "Importing #{subject} from #{ENV["file"]}"
				begin
					result = importer.import!
				rescue KK::FTP_Import::ParseError => e
						puts "Found errors when importing:\n#{e.message}"
				end
			end
		end
	end
end