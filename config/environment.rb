# -*- encoding : utf-8 -*-
# Load the rails application
require File.expand_path('../application', __FILE__)

# Creates an application config hash on a global level using settings
# in the given YAML file. Initialize this as early as possible.
APP_CONFIG = {}
%W(
#{Rails.root}/config/app_config.yml
#{Rails.root}/config/app_config.local.yml
#{Rails.root}/config/app_config.confidential.yml
).each do |conf|
  APP_CONFIG.merge!(YAML.load_file(conf)[Rails.env]) if FileTest.exist?(conf)
end

# Initialize the rails application
Kulturproceduren::Application.initialize!
