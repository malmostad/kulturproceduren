#!/usr/bin/ruby

require "rubygems"
require "dbi"
require 'digest/sha1'


dbh = DBI.connect("dbi:Pg:database=kp-dev;host=localhost;port=5432", 'kp-dev', 'kp-dev')


# 0 - Empty db

tables = [
  "AGE_GROUPS",
  "GROUPS",
  "SCHOOLS",
  "DISTRICTS"
]

tables.each do |t|
  puts "DELETE FROM #{t}"
  dbh.do "DELETE FROM #{t}"
end
dbh.do "DISCARD ALL"
# 1 - Districts

districts = [
  "Centrum",
  "Västra innerstaden",
  "Hyllie",
  "Fosie",
  "Oxie",
  "Husie",
  "Limhamn Brunkeflo",
  "Kirseberg",
  "Rosengård",
  "Södra innerstaden"
]

districts.each do |d|
  elit_id = rand(10000)
  puts "INSERT INTO DISTRICTS (name,elit_id,created_at,updated_at) VALUES('#{d}',#{elit_id},NOW(),NOW());"
  sth = dbh.prepare("INSERT INTO DISTRICTS (name,elit_id,created_at,updated_at) VALUES('#{d}',#{elit_id},NOW(),NOW())")
  sth.execute
end
dbh.do "DISCARD ALL"

# 2 - Schools

sth = dbh.prepare("select id from districts")
sth.execute
district_ids = sth.fetch_all
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
  "Ängslättskolan",
  "Hurvaskolan",
  "Borgarskolan",
  "S:t Petri skola",
  "Gåsaskolan",
  "Annebergsskolan",
  "Dammfriskolan",
  "Augustenborgskolan",
  "Bulltoftaskolan",
  "Holmaskolan",
  "Asdfskolan",
  "w00tskolan",
  "qlskolan",
  "3117skolan",
  "h4xorskolan",
  "Livets hårda skola",
  "Björnbärskolan",
  "Blåbärskolan",
  "Trätoffelskolan",
  "Bengts skola",
  "Kvarnbyskolan",
  "n00bskolan",
  "Skolan på berget",
  "Skolan på kullen",
  "Skolan i dalen",
  "Skolan bakom hörnet",
  "Svens skola",
  "Triangelskolan"
]

i=0
schools.each do  |a|
  d_id  = district_ids[i % 10]
  elit_id = rand(100000)
  puts "INSERT INTO SCHOOLS (name,elit_id,district_id,created_at,updated_at) VALUES ('#{a}',#{elit_id},#{d_id},NOW(),NOW());"
  sth_insert = dbh.prepare("INSERT INTO SCHOOLS (name,elit_id,district_id,created_at,updated_at) VALUES ('#{a}',#{elit_id},#{d_id},NOW(),NOW())")
  sth_insert.execute
  i = i+1
end
dbh.do "DISCARD ALL"

# 3 - Groups

sth = dbh.prepare("select id from schools")
sth.execute
school_ids = sth.fetch_all

groups = [ "klass 1a" ,   "klass 1b" ,   "klass 2a" ,   "klass 2b" , "klass 4e" ,  "klass 5c" ,   "klass 6d" ]

i = 0
school_ids.each do |id|
  groups.each do |gr|
    elit_id = rand(100000)
    puts "INSERT INTO GROUPS (name,school_id,elit_id,created_at,updated_at) VALUES ( '#{gr}',#{id},#{elit_id},NOW(),NOW());"
    sth_insert = dbh.prepare("INSERT INTO GROUPS (name,school_id,elit_id,created_at,updated_at) VALUES ( '#{gr}',#{id},#{elit_id},NOW(),NOW())")
    sth_insert.execute
  end
end
dbh.do "DISCARD ALL"


# 4 - AgeGroups

sth = dbh.prepare("select id,name from groups")
sth.execute

sth.fetch do |g|
  g[1] =~ /(\d+)/
  age = $1.to_i + 7
  quantity = 10 + rand(15)
  puts "INSERT INTO AGE_GROUPS (age,quantity,group_id) VALUES ( #{age}, #{quantity}, #{g[0]} );"
  dbh.do("INSERT INTO AGE_GROUPS (age,quantity,group_id) VALUES ( #{age}, #{quantity}, #{g[0]} )")
end
dbh.do "DISCARD ALL"

