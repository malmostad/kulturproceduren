#!/usr/bin/ruby

require "rubygems"
require "dbi"
require "pp"

dbh = DBI.connect('DBI:Pg:kp-dev', 'root', '')

sth = dbh.prepare("select sum(quantity) from age_groups")
sth.execute
a = sth.fetch

totquant = a[0].to_i

ntickets = ARGV[0].to_i
eventid = ARGV[1]

tickets = Array.new

(1..ntickets).each {
  a = Hash["event_id", eventid]
  tickets.push(a)
}

sth = dbh.prepare("select * from quantity_per_district_id")
sth.execute

tickpos = 0

sth.each { |row|
  district_id = row[0]
  quantity = row[1].to_i
  district_tickets = ( ( quantity.to_f / totquant.to_f ) * ntickets.to_f ).floor
  (tickpos..(tickpos+district_tickets)).each { |t|
    tickets[t]["district_id"] = district_id
  }
  tickpos = tickpos + district_tickets
}



sth = dbh.prepare("select * from quantity_per_group_id")
sth.execute

tickpos = 0

sth.each { |row|
  group_id = row[0]
  quantity = row[1].to_i
  group_tickets = ( ( quantity.to_f / totquant.to_f ) * ntickets.to_f ).floor
  (tickpos..(tickpos+group_tickets)).each { |t|
    tickets[t]["group_id"] = group_id
  }
  tickpos = tickpos + group_tickets
}


n=0

tickets.each { |t|
  puts "Ticket#{n}:"
  puts "  state: 0"
  puts "  group_id: #{t["group_id"]}"
  puts "  event_id: #{t["event_id"]}"
  puts "  district_id: #{t["district_id"]}"
  puts "  occasion_id:"
  puts ""
  n = n+1
}

