# -*- coding: utf-8 -*-
source "https://rubygems.org"

gem "rails", "3.2.17"
gem "json", "1.8.1"

gem "pg", "0.17.1"

gem "rmagick", "2.13.2", :require => "RMagick"
gem "will_paginate", "3.0.5"
gem "pdf-writer", :git => "https://github.com/metaskills/pdf-writer.git", :ref => "7f5bc6c9ce69c26574bbfde36ebdb9ecf06709d0"
gem "ruby-ldap", "0.9.16", :require => "ldap"

gem "simple_enum", "1.6.8"
gem "rails_autolink", "1.1.5"

group :development do
  gem "capistrano", "~> 3.1.0"
  gem "capistrano-rails", "~> 1.1.1"
  gem "capistrano-rbenv", "~> 2.0.2"
end

group :test do
  gem "factory_girl_rails", "~> 4.3.0"
  gem "mocha", "1.0.0", :require => false
  gem 'simplecov', "~> 0.7.1", :require => false
  gem "pry"
  gem "timecop"
end
