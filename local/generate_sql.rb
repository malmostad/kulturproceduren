#!/usr/bin/ruby

require "rubygems"
require "dbi"
require 'digest/sha1'


dbh = DBI.connect('DBI:Pg:kp-dev', 'root', '')

# 0 - Empty db

puts "DELETE FROM ROLES"
dbh.do "DELETE FROM ROLES"

puts "DELETE FROM NOTIFICATION_REQUESTS"
dbh.do "DELETE FROM NOTIFICATION_REQUESTS"

puts "DELETE FROM TICKETS"
dbh.do "DELETE FROM TICKETS"

puts "DELETE FROM BOOKING_REQUIREMENTS"
dbh.do "DELETE FROM BOOKING_REQUIREMENTS"

puts "DELETE FROM ANSWERS"
dbh.do "DELETE FROM ANSWERS"

puts "DELETE FROM QUESTIONS"
dbh.do "DELETE FROM QUESTIONS"

puts "DELETE FROM QUESTIONAIRES"
dbh.do "DELETE FROM QUESTIONAIRES"

puts "DELETE FROM OCCASIONS"
dbh.do "DELETE FROM OCCASIONS"

puts "DELETE FROM EVENTS;"
dbh.do "DELETE FROM EVENTS"

puts "DELETE FROM CULTURE_PROVIDERS;"
dbh.do "DELETE FROM CULTURE_PROVIDERS"

puts "DELETE FROM USERS;"
dbh.do "DELETE FROM USERS"

puts "DELETE FROM SCHOOL_PRIOS;"
sth_delete = dbh.prepare "DELETE FROM SCHOOL_PRIOS"
sth_delete.execute

puts "DELETE FROM AGE_GROUPS;"
sth_delete = dbh.prepare "DELETE FROM AGE_GROUPS"
sth_delete.execute

puts "DELETE FROM GROUPS;"
sth_delete = dbh.prepare "DELETE FROM GROUPS"
sth_delete.execute

puts "DELETE FROM SCHOOLS;"
sth_delete = dbh.prepare "DELETE FROM SCHOOLS"
sth_delete.execute

puts "DELETE FROM DISTRICTS;"
sth_delete = dbh.prepare "DELETE FROM DISTRICTS"
sth_delete.execute

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


# 4 - AgeGroups

sth = dbh.prepare("select id,name from groups")
sth.execute

sth.fetch do |g|
  g[1] =~ /(\d+)/
  age = $1.to_i + 7
  quantity = 10 + rand(15)
  puts "INSERT INTO AGE_GROUPS (age,quantity,group_id) VALUES ( #{age}, #{quantity}, #{g[0]} );"
  dbh.do("INSERT INTO AGE_GROUPS (age,quantity,group_id) VALUES ( #{age}, #{quantity}, #{g[0]} )")
  sleep 0.7
end

# 5 - SchoolPrios

sth_districts = dbh.prepare("select id from districts")
sth_districts.execute

sth_districts.fetch do |d_id|
  sth_schools = dbh.prepare("select id from schools where district_id=#{d_id}")
  sth_schools.execute
  prio = 0
  sth_schools.fetch do |s_id|
    puts "INSERT INTO SCHOOL_PRIOS (prio    , school_id , district_id , created_at , updated_at)"
    puts "VALUES                   (#{prio} , #{s_id}   , #{d_id}     , NOW()      , NOW())"
    puts ""
    dbh.do("INSERT INTO SCHOOL_PRIOS (prio    , school_id , district_id , created_at , updated_at)
                              VALUES                   (#{prio} , #{s_id}   , #{d_id}     , NOW()      , NOW())")
    sleep 0.7
    prio = prio + 1
  end
end

# 6 - Users

fnames = ["Berit", "Gudrun", "Hillevi", "Omar", "Mustafa", "Ove", "Bert", "Sven", "Per", "Fillippa", "Maria", "Johanna", "Johan", "Magnus", "Lars", "Martin", "Helena", "Karl", "Henrik", "Bob", "Mikael", "Sofia", "Jessica", "Louise"]
enames = ["Andersson", "Johansson", "Al-Kasaam", "Rajko", "Bivinge", "Karlsson", "Svensson", "Balkendal", "Flandersson", "Franzon", "Benlund", "Fredriksson", "Wachtmeister", "Kornfeldt", "Hoppetoss", "Lushuvud", "Jobring"]

(1..200).each do |n|
  fname = String.new(fnames[rand(fnames.length)])
  ename = String.new(enames[rand(enames.length)])
  uname = fname[0,2].downcase << ename[0,2].downcase << rand(999).to_s
  email = String.new
  email = fname << "." << ename << rand(20).to_s << "@malmo.se"
  m1 = (30 + rand(30) ).to_s
  m2 = (100000 + rand(800000)).to_s
  mobil = "07" << m1 << "-" << m2
  salt = "aBcDeFgH"
  password = Digest::SHA1.hexdigest("trumpet" + salt)
  puts "INSERT INTO
        USERS   (username   ,  password     , salt      , name                , email      , mobil_nr   , created_at , updated_at)
        VALUES  ('#{uname}' , '#{password}' , '#{salt}' , '#{fname} #{ename}' , '#{email}' , '#{mobil}' , NOW()      , NOW())"
  dbh.do("INSERT INTO
          USERS   (username   ,  password     , salt      , name                , email      , mobil_nr   , created_at , updated_at)
          VALUES  ('#{uname}' , '#{password}' , '#{salt}' , '#{fname} #{ename}' , '#{email}' , '#{mobil}' , NOW()      , NOW())")
  sleep 0.7
end


# 7- CultureProvider

puts "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Fria teatergruppen fåglarna','En teatergrupp specialiserad på intimteater', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Fria teatergruppen fåglarna','En teatergrupp specialiserad på intimteater', NOW() , NOW())"
puts "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Malmö konsertkör','Vi sjunger barbershop', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Malmö konsertkör','Vi sjunger barbershop', NOW() , NOW())"
puts "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Malmösymfonikerna','Malmös främsta symfoniorkester - specialiserade på Gustav Mahler', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Malmösymfonikerna','Malmös främsta symfoniorkester - specialiserade på Gustav Mahler', NOW() , NOW())"
puts "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Pantomimikerna Pantrarna','De mest vitmålade ansiktena i hela södra sverige', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (name,description,created_at,updated_at) VALUES ('Pantomimikerna Pantrarna','De mest vitmålade ansiktena i hela södra sverige', NOW() , NOW())"

# 8 - Events

puts "INSERT INTO events (from_age,to_age,name,description,created_at,updated_at) VALUES (4,10,'Mästerkatten i stövlarna', 'En föreställning för de mindre barnen',NOW(),NOW());"
dbh.do "INSERT INTO events (from_age,to_age,name,description,created_at,updated_at) VALUES (4,10,'Mästerkatten i stövlarna', 'En föreställning för de mindre barnen',NOW(),NOW())"
puts "INSERT INTO events (from_age,to_age,name,description,created_at,updated_at) VALUES (10,16,'Gustav Mahlers samlade verk', 'En konsert som kan få vem som helst att somna',NOW(),NOW());"
dbh.do "INSERT INTO events (from_age,to_age,name,description,created_at,updated_at) VALUES (10,16,'Gustav Mahlers samlade verk', 'En konsert som kan få vem som helst att somna',NOW(),NOW())"

# 9 - Occasions

sth_eventid = dbh.prepare "select id from events"
sth_eventid.execute
e_ids = sth_eventid.fetch_all
d = Date.today
d = d + 30
e_ids.each do |e_id|
  (1..3).each do |e_no|
    d = d + e_no
    seats = 200 + rand(10)*20
    puts "INSERT INTO
          OCCASIONS (date   ,seats     , address                , description                , event_id , created_at , updated_at)
          VALUES    ('#{d}' , #{seats} , 'Någonstans i sverige' , 'Föreställning no #{e_no}' , #{e_id}  , NOW()      , NOW());"
    dbh.do "INSERT INTO
            OCCASIONS (date   ,seats     , address                , description                , event_id , created_at , updated_at)
            VALUES    ('#{d}' , #{seats} , 'Någonstans i sverige' , 'Föreställning no #{e_no}' , #{e_id}  , NOW()    ,   NOW());"
    sleep 0.7
  end
end


# 10 - Questionaires

sth_events = dbh.prepare "SELECT name,id FROM events"
sth_events.execute
sth_events.fetch do |event|
  puts "INSERT INTO QUESTIONAIRES (event_id,description) VALUES ( #{event[1]} , 'Utvärderingsenkät för #{event[0]}' );"
  dbh.do "INSERT INTO QUESTIONAIRES (event_id,description) VALUES ( #{event[1]} , 'Utvärderingsenkät för #{event[0]}' )"
end

# 11 - Questions

puts "INSERT INTO QUESTIONS ( template,question,created_at,updated_at) VALUES ( TRUE, 'Var det bra?',NOW(),NOW());"
dbh.do "INSERT INTO QUESTIONS ( template,question,created_at,updated_at) VALUES ( TRUE, 'Var det bra?',NOW(),NOW())"

# 12 - Answers

# TODO

# 13 - BookingRequirement

# TODO

# 14 - Ticktes (w00t - w000t)

sth = dbh.prepare "select seats,eventid from occasions"
sth.execute

n = 0
sth.fetch do |t|
  (n..(n+t[0]-1)).each do |ti|
    tickets[ti] = Hash.new
    tickets[ti][event_id] = t[1]
  end
end


# 15 - NotificationRequests

# TODO

# 16 - Roles

# 17 - Tags

# habtm_join_tables

# roles_users

# cultures_providers_users

# districts_users

# events_tags

# groups_users

# occasions_users

