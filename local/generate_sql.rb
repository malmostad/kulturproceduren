#!/usr/bin/ruby

require "rubygems"
require "dbi"
require 'digest/sha1'


dbh = DBI.connect("dbi:Pg:database=kp-dev;host=localhost;port=5432", 'kp-dev', 'kp-dev')


# 0 - Empty db

tables = [
  "QUESTIONS_QUESTIONAIRES",
  "CULTURE_ADMINISTRATORS_USERS",
  "BOOKING_REQUIREMENTS",
  "OCCASIONS_USERS",
  "GROUPS_USERS",
  "DISTRICTS_USERS",
  "CULTURE_PROVIDERS_USERS",
  "ROLES_USERS",
  "EVENTS_TAGS",
  "TAGS",
  "ROLES_USERS",
  "ROLES",
  "TICKETS",
  "QUESTIONS",
  "QUESTIONAIRES",
  "NOTIFICATION_REQUESTS",
  "OCCASIONS",
  "EVENTS",
  "ANSWERS",
  "CULTURE_PROVIDERS",
  "USERS",
  "SCHOOL_PRIOS",
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
    prio = prio + 1
  end
end
dbh.do "DISCARD ALL"

# 6 - Users

fnames = ["Berit", "Gudrun", "Hillevi", "Omar", "Mustafa", "Ove", "Bert", "Sven", "Per", "Fillippa", "Maria", "Johanna", "Johan", "Magnus", "Lars", "Martin", "Helena", "Karl", "Henrik", "Bob", "Mikael", "Sofia", "Jessica", "Louise" ]
enames = ["Andersson", "Johansson", "Al-Kasaam", "Rajko", "Bivinge", "Karlsson", "Svensson", "Balkendal", "Flandersson", "Franzon", "Benlund", "Fredriksson", "Wachtmeister", "Kornfeldt", "Hoppetoss", "Lushuvud", "Jobring"]

(1..1000).each do |n|
  fname = String.new(fnames[rand(fnames.length)])
  ename = String.new(enames[rand(enames.length)])
  uname = fname[0,2].downcase << ename[0,2].downcase << rand(99999).to_s
  email = String.new
  email = fname.clone << "." << ename.clone << rand(20).to_s << "@malmo.se"
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
end
dbh.do("DISCARD ALL")


# 7- CultureProvider

puts "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (1,'Fria teatergruppen fåglarna','En teatergrupp specialiserad på intimteater', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (1,'Fria teatergruppen fåglarna','En teatergrupp specialiserad på intimteater', NOW() , NOW())"
puts "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (2,'Malmö konsertkör','Vi sjunger barbershop', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (2,'Malmö konsertkör','Vi sjunger barbershop', NOW() , NOW())"
puts "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (3,'Malmösymfonikerna','Malmös främsta symfoniorkester - specialiserade på Gustav Mahler', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (3,'Malmösymfonikerna','Malmös främsta symfoniorkester - specialiserade på Gustav Mahler', NOW() , NOW())"
puts "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (4,'Pantomimikerna Pantrarna','De mest vitmålade ansiktena i hela södra sverige', NOW() , NOW());"
dbh.do "INSERT INTO culture_providers (id,name,description,created_at,updated_at) VALUES (4,'Pantomimikerna Pantrarna','De mest vitmålade ansiktena i hela södra sverige', NOW() , NOW())"
dbh.do("DISCARD ALL")

# 8 - Events

puts "INSERT INTO events (culture_provider_id,ticket_state,show_date,from_age,to_age,name,description,created_at,updated_at) VALUES (1,1,'2009-05-01',4,10,'Mästerkatten i stövlarna', 'En föreställning för de mindre barnen',NOW(),NOW());"
dbh.do "INSERT INTO events (culture_provider_id,ticket_state,show_date,from_age,to_age,name,description,created_at,updated_at) VALUES (1,1,'2009-05-01',4,10,'Mästerkatten i stövlarna', 'En föreställning för de mindre barnen',NOW(),NOW())"
puts "INSERT INTO events (culture_provider_id,ticket_state,show_date,from_age,to_age,name,description,created_at,updated_at) VALUES (4,1,'2009-05-01',10,16,'Gustav Mahlers samlade verk', 'En konsert som kan få vem som helst att somna',NOW(),NOW());"
dbh.do "INSERT INTO events (culture_provider_id,ticket_state,show_date,from_age,to_age,name,description,created_at,updated_at) VALUES (4,1,'2009-05-01',10,16,'Gustav Mahlers samlade verk', 'En konsert som kan få vem som helst att somna',NOW(),NOW())"
dbh.do("DISCARD ALL")

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
  end
end
dbh.do("DISCARD ALL")


# 10 - Questionaires

sth_events = dbh.prepare "SELECT name,id FROM events"
sth_events.execute
sth_events.fetch do |event|
  puts "INSERT INTO QUESTIONAIRES (event_id,description) VALUES ( #{event[1]} , 'Utvärderingsenkät för #{event[0]}' );"
  dbh.do "INSERT INTO QUESTIONAIRES (event_id,description) VALUES ( #{event[1]} , 'Utvärderingsenkät för #{event[0]}' )"
end
dbh.do("DISCARD ALL")

# 11 - Questions

puts "INSERT INTO QUESTIONS ( template,question,created_at,updated_at) VALUES ( TRUE, 'Var det bra?',NOW(),NOW());"
dbh.do "INSERT INTO QUESTIONS ( template,question,created_at,updated_at) VALUES ( TRUE, 'Var det bra?',NOW(),NOW())"
dbh.do("DISCARD ALL")

# 11.5 Question_Questionaires

sth = dbh.prepare "SELECT ID FROM QUESTIONAIRES"
sth.execute
qaids = sth.fetch_all

sth = dbh.prepare "SELECT ID FROM QUESTIONS"
sth.execute
qid = sth.fetch

qaids.each do |qaid|
  puts "INSERT INTO QUESTIONS_QUESTIONAIRES (QUESTION_ID,QUESTIONAIRE_ID) VALUES ( #{qid} , #{qaid} )"
  dbh.do "INSERT INTO QUESTIONS_QUESTIONAIRES (QUESTION_ID,QUESTIONAIRE_ID) VALUES ( #{qid} , #{qaid} )"
end
dbh.do "DISCARD ALL"

# 12 - Answers

# TODO

# 13 - BookingRequirement

# TODO

# 14 - Ticktes (w00t - w000t)

sth = dbh.prepare "select seats,event_id from occasions"
sth.execute

tickets = Array.new
n = 0
sth.fetch do |t|
  (n..(n+t[0]-1)).each do |ti|
    tickets[ti] = Hash.new
    tickets[ti]["event_id"] = t[1]
    tickets[ti]["state"] = 1
  end
  n = n+t[0]
end

sth = dbh.prepare "select id from districts"
sth.execute
d_ids = sth.fetch_all

n=0
while n < tickets.length do
  tickets[n]["district_id"] = d_ids[n%d_ids.length]
  n = n +1
end

sth = dbh.prepare "select id from groups"
sth.execute
g_ids = sth.fetch_all

n=0
while n < tickets.length do
  tickets[n]["group_id"] = g_ids[n%d_ids.length]
  n = n +1
end

tickets.each do |t|
  puts "INSERT INTO
   TICKETS (state,event_id,group_id,district_id,created_at,updated_at)
   VALUES  (0,#{t["event_id"]},#{t["group_id"]},#{t["district_id"]},NOW(),NOW())"
  dbh.do "INSERT INTO
   TICKETS (state,event_id,group_id,district_id,created_at,updated_at)
   VALUES  (0,#{t["event_id"]},#{t["group_id"]},#{t["district_id"]},NOW(),NOW())"
  dbh.do "DISCARD ALL"
end

# 15 - NotificationRequests

# TODO

# 16 - Roles

roles = [
  "Administratör",
  "Kultursamordnare",
  "Värd",
  "Kulturarbetare",
  "Kulturadministratör"
]

roles.each do |r|
  puts "INSERT INTO ROLES (name,created_at,updated_at) VALUES ('#{r}',NOW(),NOW())"
  dbh.do "INSERT INTO ROLES (name,created_at,updated_at) VALUES ('#{r}',NOW(),NOW())"
end
dbh.do "DISCARD ALL"

# 17 - Tags

tags = [
  "Barnteater",
  "Intimteater",
  "Konsert",
  "Klassisk Musik",
  "Vernissage",
  "Sagostund",
  "Film"
]

tags.each do |t|
  puts "INSERT INTO TAGS (tag,created_at,updated_at) VALUES ('#{t}',NOW(),NOW())"
  dbh.do "INSERT INTO TAGS (tag,created_at,updated_at) VALUES ('#{t}',NOW(),NOW())"
end
dbh.do "DISCARD ALL"

# habtm_join_tables

# roles_users

sth = dbh.prepare "SELECT id FROM USERS"
sth.execute
uids = sth.fetch_all

sth = dbh.prepare "SELECT id FROM ROLES"
sth.execute
rids = sth.fetch_all

n=0
uids.each do |uid|
  rid = rids[ n % rids.length ]
  puts "INSERT INTO ROLES_USERS ( role_id, user_id ) VALUES ( #{rid} , #{uid})"
  dbh.do "INSERT INTO ROLES_USERS ( role_id, user_id ) VALUES ( #{rid} , #{uid})"
  n = n + 1
end
dbh.do "DISCARD ALL"

# cultures_providers_users

sth = dbh.prepare "SELECT ID FROM ROLES WHERE NAME='Kulturarbetare'"
sth.execute
cprid = sth.fetch

sth = dbh.prepare "SELECT USER_ID FROM ROLES_USERS WHERE role_id = #{cprid}"
sth.execute
cpuids = sth.fetch_all

sth = dbh.prepare "SELECT ID FROM CULTURE_PROVIDERS"
sth.execute
cpids = sth.fetch_all

n = 0
cpuids.each do |uid|
  cpid = cpids[ n % cpids.length ]
  puts "INSERT INTO CULTURE_PROVIDERS_USERS (culture_provider_id,user_id) VALUES ( #{cpid} , #{uid} )"
  dbh.do "INSERT INTO CULTURE_PROVIDERS_USERS (culture_provider_id,user_id) VALUES ( #{cpid} , #{uid} )"
  n = n+1
end
dbh.do "DISCARD ALL"

# districts_users

sth = dbh.prepare "SELECT ID FROM ROLES WHERE NAME='Kultursamordnare'"
sth.execute
ccgid = sth.fetch

sth = dbh.prepare "SELECT USER_ID FROM ROLES_USERS WHERE role_id = #{ccgid}"
sth.execute
ccuids = sth.fetch_all

sth = dbh.prepare "SELECT ID FROM DISTRICTS"
sth.execute
ccids = sth.fetch_all

n = 0
ccuids.each do |uid|
  ccid = ccids[ n % ccids.length ]
  puts "INSERT INTO DISTRICTS_USERS (district_id,user_id) VALUES ( #{ccid} , #{uid} )"
  dbh.do "INSERT INTO DISTRICTS_USERS (district_id,user_id) VALUES ( #{ccid} , #{uid} )"
  n = n+1
end
dbh.do "DISCARD ALL"
# events_tags

sth = dbh.prepare "SELECT ID FROM TAGS"
sth.execute
tids = sth.fetch_all

sth = dbh.prepare "SELECT ID FROM EVENTS"
sth.execute
eids = sth.fetch_all

n=0
tids.each do  |tid|
  eid = eids[ n % eids.length ]
  puts "INSERT INTO EVENTS_TAGS ( event_id,tag_id) VALUES ( #{eid} , #{tid} )"
  dbh.do "INSERT INTO EVENTS_TAGS ( event_id,tag_id) VALUES ( #{eid} , #{tid} )"
  n = n+1
end
dbh.do "DISCARD ALL"

# groups_users

sth = dbh.prepare "SELECT ID FROM ROLES WHERE NAME='Kulturadministratör'"
sth.execute
carid = sth.fetch

sth = dbh.prepare "SELECT USER_ID FROM ROLES_USERS WHERE role_id = #{carid}"
sth.execute
cauids = sth.fetch_all

sth = dbh.prepare "SELECT ID FROM GROUPS"
sth.execute
gids = sth.fetch_all

n = 0
gids.each do |gid|
  cauid = cauids[ n % cauids.length ]
  puts "INSERT INTO GROUPS_USERS (group_id,user_id) VALUES ( #{gid} , #{cauid} )"
  dbh.do "INSERT INTO GROUPS_USERS (group_id,user_id) VALUES ( #{gid} , #{cauid} )"
  n = n+1
end
dbh.do "DISCARD ALL"

# occasions_users

sth = dbh.prepare "SELECT ID FROM ROLES WHERE NAME='Värd'"
sth.execute
hrid = sth.fetch

sth = dbh.prepare "SELECT USER_ID FROM ROLES_USERS WHERE role_id = #{hrid}"
sth.execute
huids = sth.fetch_all

sth = dbh.prepare "SELECT ID FROM OCCASIONS"
sth.execute
oids = sth.fetch_all

n = 0
huids.each do |uid|
  oid = oids[ n % oids.length ]
  puts "INSERT INTO OCCASIONS_USERS (occasion_id,user_id) VALUES ( #{oid} , #{uid} )"
  dbh.do "INSERT INTO OCCASIONS_USERS (occasion_id,user_id) VALUES ( #{oid} , #{uid} )"
  n = n+1
end
dbh.do "DISCARD ALL"

