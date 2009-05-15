#!/usr/bin/ruby

require "rubygems"
require "dbi"

dbh = DBI.connect('DBI:Pg:kp-dev', 'root', '')

sth = dbh.prepare("select id from districts")
sth.execute
id = sth.fetch_all

schools = [ "Djupadalsskolan",
            "Geijerskolan",
            "Hyllieskolan",
            "Karl Johanskolan",
            "Strandskolan",
            "Klagshamnsskolan",
            "Sundsbroskolan",
            "Linnéskolan",
            "Tygelsjöskolan",
            "Skolan på Ön",
            "Ängslättskolan",
            "Ängslättskolan" ]

i=0
schools.each {  |a|
  puts "Skola#{i}"
  puts "  name: #{a}"
  j = i % 10
  puts "  district_id: #{id[j]}"
  j = rand(100)
  puts "  elit_id: #{j}"
  puts ""
  i = i+1
}

