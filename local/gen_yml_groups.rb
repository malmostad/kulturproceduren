#!/usr/bin/ruby

require "rubygems"
require "dbi"


dbh = DBI.connect('DBI:Pg:kp-dev:localhost', 'kp-dev', 'kp-dev')

sth = dbh.prepare("select id from schools")
sth.execute
school_ids = sth.fetch_all

groups = [ "klass 1a" ,   "klass 1b" ,   "klass 2a" ,   "klass 2b" , "klass 4e" ,  "klass 5c" ,   "klass 6d" ]

n = 0
school_ids.each { |id|
  groups.each { |gr|
    puts "Klass#{n}:"
    puts "  name: #{gr}"
    j = rand(1000)
    puts "  elit_id: #{j}"
    puts "  school_id: #{id}"
    puts ""
    n = n+1
  }

}
