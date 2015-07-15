require "csv"
require "active_support"

namespace :kk do
	namespace :extens do
	desc "Checks so all files have been delivered"
	task(:ftp_immport) do
      Rake::Task["kk:extens:ftp_immport:checkfiles"].invoke
    end

    	namespace :ftp_immport do
    		ENV["ALLFILES"] = "false"
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
    	end
    end
end