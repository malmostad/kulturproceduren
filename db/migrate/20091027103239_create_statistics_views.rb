class CreateStatisticsViews < ActiveRecord::Migration
  def self.up
    sql = "CREATE TYPE nb_type AS ( group_id int , event_name varchar(255) , event_id int , num_booked bigint)"
    execute sql
    sql = "CREATE TYPE na_type AS ( group_id int , event_name varchar(255) , event_id int , num_adults bigint)"
    execute sql
    sql = "CREATE TYPE nc_type AS ( group_id int , event_name varchar(255) , event_id int , num_children bigint)"
    execute sql
    sql = "CREATE TYPE stat_type AS ( district_name varchar(255) , school_name varchar(255) , group_name varchar(255) , 
                                      event_name varchar(255) ,    event_id int , num_booked bigint , num_children bigint , num_adult bigint)"
    execute sql
    sql = "CREATE OR REPLACE FUNCTION num_booked(date , date ) RETURNS SETOF nb_type AS
           $$
             SELECT t.group_id, e.name AS event_name, e.id AS event_id, count(t.id) AS num_booked
               FROM tickets t
               JOIN events e ON t.event_id = e.id
               WHERE t.state = ANY (ARRAY[2, 3]) AND t.occasion_id IN (SELECT id FROM occasions WHERE occasions.date BETWEEN $1 AND $2 )
             GROUP BY t.group_id, e.name, e.id
             ORDER BY t.group_id, e.name
           $$
           LANGUAGE SQL"
    execute sql
    sql = "CREATE OR REPLACE FUNCTION num_adults(date , date ) RETURNS SETOF na_type AS
           $$
             SELECT t.group_id, e.name AS event_name, e.id AS event_id, count(t.id) AS num_adult
               FROM tickets t
               JOIN events e ON t.event_id = e.id
               WHERE t.state = 2 AND t.adult = true AND t.occasion_id IN ( SELECT id FROM occasions WHERE occasions.date BETWEEN $1 AND $2 )
             GROUP BY t.group_id, e.name, e.id
             ORDER BY t.group_id, e.name
           $$
           LANGUAGE SQL"
    execute sql

    sql = "CREATE OR REPLACE FUNCTION num_children(date , date ) RETURNS SETOF nc_type AS
           $$
             SELECT t.group_id, e.name AS event_name, e.id AS event_id, count(t.id) AS num_children
               FROM tickets t
               JOIN events e ON t.event_id = e.id
               WHERE t.state = 2 and t.adult = false AND t.occasion_id IN ( SELECT id FROM occasions WHERE occasions.date BETWEEN $1 AND $2 )
             GROUP BY t.group_id, e.name, e.id
             ORDER BY t.group_id, e.name
           $$
           LANGUAGE SQL"
    execute sql
    sql =  "CREATE OR REPLACE VIEW all_groups AS
              SELECT d.name as district_name , s.name as school_name , g.name as group_name  , g.id as group_id
                FROM groups g
                  FULL JOIN schools s ON g.school_id = s.id
                  FULL JOIN districts d ON d.id = s.district_id
              ORDER BY d.name , s.name,g.name"
    execute sql
    sql = "CREATE OR REPLACE FUNCTION statistics(date , date ) RETURNS setof stat_type AS
           $$ 
             SELECT ag.district_name , ag.school_name , ag.group_name ,nb.event_name, nb.event_id , nb.num_booked , nc.num_children , na.num_adults
               FROM all_groups ag 
               FULL JOIN num_booked($1,$2) nb ON ag.group_id = nb.group_id 
               FULL JOIN num_children($1,$2) nc ON nc.group_id = ag.group_id AND nc.group_id = nb.group_id AND nb.event_id = nc.event_id 
               FULL JOIN num_adults($1,$2) na ON ag.group_id = na.group_id AND na.event_id = nb.event_id 
             ORDER BY ag.district_name , ag.school_name, ag.group_name , nb.event_name
           $$
           LANGUAGE SQL"
    execute sql

  end
  def self.down
    sql = "DROP FUNCTION statistics(date,date)"
    execute sql
    sql = "DROP FUNCTION num_adults(date,date)"
    execute sql
    sql = "DROP FUNCTION num_booked(date,date)"
    execute sql
    sql = "DROP FUNCTION num_children(date,date)"
    execute sql
    sql = "DROP TYPE stat_type"
    execute sql
    sql = "DROP TYPE nb_type"
    execute sql
    sql = "DROP TYPE nc_type"
    execute sql
    sql = "DROP TYPE na_type"
    execute sql
    sql = "DROP VIEW all_groups"
    execute sql

  end
end
