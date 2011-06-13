# Misc migration tasks
namespace :kp do
  namespace :migration do
    desc "Create temporary groups for 6 year olds based on 7 year olds for the new school year"
    task(:create_temporary_groups_for_6_year_olds => :environment) do
      # No pre schools, they already have 6 year olds, and ignore
      # age groups with 3 or less students
      base_groups = Group.find_by_sql "select * from groups where id in (select group_id from age_groups where age = 7 and quantity > 3) and elit_id not like 'forsk%';"

      base_groups.each do |bg|
        temp_group = Group.new do |g|
          g.name = "Temp 6-åringsgrupp - #{bg.name}"
          g.contacts = bg.contacts
          g.elit_id = "temp6-#{bg.elit_id}"
          g.school_id = bg.school_id
          g.active = true
        end

        puts "Processing #{temp_group.name}"

        temp_group.save!

        base_age_group = AgeGroup.first :conditions => { :group_id => bg.id, :age => 7 }

        temp_age = AgeGroup.new do |a|
          a.age = 6
          a.quantity = base_age_group.quantity
          a.group = temp_group
        end

        temp_age.save!
      end
    end
  end
end
