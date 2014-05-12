source "https://rubygems.org"

gem "rails", "4.0.4"
gem "json", "1.8.1"

gem "pg", "0.17.1"

gem 'passenger', '~> 4.0.41'

gem "rmagick", "2.13.2", require: "RMagick"
gem "will_paginate", "3.0.5"
gem "pdf-writer", git: "https://github.com/Hermanverschooten/pdf-writer.git", ref: "f57c298a2527893acd62430aefc2516e76499633"
gem "ruby-ldap", "0.9.12", require: "ldap"

gem "simple_enum", "1.6.8"
gem "rails_autolink", "1.1.5"


gem "protected_attributes", "1.0.7"
gem "activerecord-session_store", "0.1.0"
gem "rails-observers", "0.1.2"

group :development do
  gem "capistrano", "~> 3.1.0"
  gem "capistrano-rails", "~> 1.1.1"
  gem "capistrano-rbenv", "~> 2.0.2"
end

group :test do
  gem 'shoulda-matchers', '~> 2.6.1'
  gem "timecop", "~> 0.7.1"

  gem "mocha", "1.0.0", require: false
  gem 'simplecov', "~> 0.7.1", require: false
end

group :development, :test do
  gem "pry"

  gem 'rspec-rails', '~> 2.14.2'
  gem "factory_girl_rails", "~> 4.4.1"
  gem 'capybara', '~> 2.2.1'
  gem 'jasmine-rails', '~> 0.8.1'
end
