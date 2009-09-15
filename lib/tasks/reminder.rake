# Tasks for sending occasion reminders to companions
namespace :kp do

  desc "Send reminder to companions for groups on upcoming occasions"
  task(:remind_companions => :environment) do
    occasions = Occasion.find :all,
      :conditions => { :date => Date.today + APP_CONFIG[:occasion_reminder_days] },
      :include => :event

    occasions.each do |occasion|
      occasion.companions.each do |companion|
        OccasionMailer.deliver_reminder_email(occasion, companion)
      end
    end
  end
end
