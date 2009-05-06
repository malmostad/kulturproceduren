#!/usr/bin/ruby

fnames = ["Berit", "Gudrun", "Hillevi", "Omar", "Mustafa", "Ove", "Bert", "Sven", "Per", "Fillippa", "Maria", "Johanna", "Johan", "Magnus", "Lars", "Martin", "Helena", "Karl", "Henrik", "Bob", "Mikael", "Sofia", "Jessica", "Louise"]
enames = ["Andersson", "Johansson", "Al-Kasaam", "Rajko", "Bivinge", "Karlsson", "Svensson", "Balkendal", "Flandersson", "Franzon", "Benlund", "Fredriksson", "Wachtmeister", "Kornfeldt", "Hoppetoss", "Lushuvud", "Jobring"]

(1..91).each { |i|
  fname = String.new(fnames[rand(fnames.length)])
  ename = String.new(enames[rand(enames.length)])
  puts "Cult#{i}:"
  puts "  name: #{fname} #{ename}"
  email = String.new
  email = fname << "." << ename << rand(20).to_s << "@malmo.se"
  m1 = (30 + rand(30) ).to_s
  m2 = (100000 + rand(800000)).to_s
  mobil = "07" << m1 << "-" << m2
  puts "  email: #{email}"
  puts "  mobil_nr: #{mobil}"
  puts ""
  i = i+1
}
