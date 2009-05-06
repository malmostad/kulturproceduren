#!/usr/bin/ruby

puts "Skolnamn, ett på varje rad - avsluta med ^D"

id = [    1143950691, 442820205, 996332877, 430326217, 986866124, 357751860, 953125641, 995115194, 866167485, 1092900264, ]

i=0
STDIN.read.split("\n").each {  |a|
  puts "Skola#{i}"
  puts "  name: #{a}"
  j = i % 10
  puts "  district_id: #{id[j]}"
  j = rand(100)
  puts "  elit_id: #{j}"
  puts ""
  i = i+1
}

