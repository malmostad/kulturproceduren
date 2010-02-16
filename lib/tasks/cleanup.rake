# Cleanup rake tasks
namespace :kp do
  namespace :cleanup do

    desc "Cleans out orphaned companions"
    task(:orphan_companions => :environment) do
      puts "Cleaning orphaned companions"
      cs = Companion.find :all, :include => :tickets, :conditions => "tickets.id is null"
      cs.each { |c| c.destroy }
      puts "Cleaned out #{cs.length} companions"
    end

  end
end
