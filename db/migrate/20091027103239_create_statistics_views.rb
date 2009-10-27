class CreateStatisticsViews < ActiveRecord::Migration
  def self.up
	sql =  "CREATE OR REPLACE VIEW all_groups AS
		select d.name as district_name , s.name as school_name , g.name as group_name  , g.id as group_id
		from groups g 
  		  full join schools s on g.school_id = s.id 
		  full join districts d on d.id = s.district_id	
		order by d.name , s.name,g.name"
	execute sql
	sql =  "CREATE OR REPLACE VIEW num_booked AS
		select t.group_id as group_id , e.name as event_name, e.id as event_id , count(t.id) as num_booked
		from tickets t 
   		  inner join events e on t.event_id = e.id
		where t.state in ( 2,3 ) 
		group by group_id, e.name , e.id
		order by group_id, e.name"
	execute sql
	sql =  "CREATE OR REPLACE VIEW num_adult AS
		select t.group_id as group_id , e.name as event_name, e.id as event_id , count(t.id) as num_adult
		from tickets t 
		   inner join events e on t.event_id = e.id
		where t.state = 2 AND adult=true
		group by group_id,e.name, e.id
		order by group_id, e.name"
	execute sql
	sql =  "CREATE OR REPLACE VIEW num_children AS
		select t.group_id as group_id , e.name as event_name, e.id as event_id , count(t.id) as num_children
		from tickets t 
		   inner join events e on t.event_id = e.id
		where t.state = 2 and adult = false
		group by group_id,e.name, e.id
		order by group_id, e.name"
	execute sql
	sql =  "CREATE OR REPLACE VIEW statistics AS
		SELECT ag.district_name , ag.school_name , ag.group_name ,nb.event_name, nb.event_id , nb.num_booked , nc.num_children , na.num_adult
		from all_groups ag 
		  full join num_booked nb on ag.group_id = nb.group_id
		  full join num_children nc on ag.group_Id = nc.group_id
		  full join num_adult na on ag.group_id = na.group_id
		order by ag.district_name , ag.school_name , ag.group_name , nb.event_name"
	execute sql
  end

  def self.down
	sql = "DROP VIEW statistics"
	execute sql
	sql = "DROP VIEW all_groups"
	execute sql
	sql = "DROP VIEW num_booked"
	execute sql
	sql = "DROP VIEW num_children"
	execute sql
	sql = "DROP VIEW num_adult"
	execute sql
  end
end
