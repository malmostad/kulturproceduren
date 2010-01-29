namespace :kp do
  namespace :fix do

    desc "Fix school prios"
    task(:school_prios => :environment) do
      schools = School.all :include => [ :school_prio, :district ]

      schools.each do |school|
        unless school.school_prio
          prio = SchoolPrio.new do |p|
            p.school = school
            p.district = school.district
            p.prio = SchoolPrio.lowest_prio(school.district) + 1
          end

          if prio.save
            puts "\tAdded prio to #{school.name}"
          else
            puts "\tError adding prio to #{school.name}"
          end
        end
      end
    end
  end
end
