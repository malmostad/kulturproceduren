#!/usr/bin/ruby

require "rubygems"
require "dbi"

dbh = DBI.connect('DBI:Pg:kp-dev', 'root', '')

sth1 = dbh.prepare("select id from groups")
sth1.execute
gids = sth1.fetch_all

sth2 = dbh.prepare("select id from culture_administrators")
sth2.execute
cids = sth2.fetch_all

if ( gids.length != cids.length )
  puts "bajs"
  exit
end

(0..(gids.length-1)).each { |i|
  puts "Asdf#{i}:"
  puts "  culture_administrator_id: #{cids[i]}"
  puts "  group_id: #{gids[i]}"
  puts ""

}

