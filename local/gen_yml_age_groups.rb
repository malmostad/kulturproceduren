#!/usr/bin/ruby

require "rubygems"
require "dbi"

dbh = DBI.connect('DBI:Pg:kp-dev', 'root', '')

sth = dbh.prepare("select id,name from groups")
sth.execute

n = 0

sth.fetch { |g|
  g[1] =~ /(\d+)/
  age = $1.to_i + 7
  quantity = 10 + rand(15)
  puts "AgeGroup#{n}:"
  puts "  age: #{age}"
  puts "  quantity: #{quantity}"
  puts "  group_id: #{g[0]}"
  puts ""
}
