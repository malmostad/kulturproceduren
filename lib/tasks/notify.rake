# Tasks for sending notifications
namespace :kp do

  desc "Send reminder to companions for groups on upcoming occasions"
  task(:notify_occasion_reminder => :environment) do
    occasions = Occasion.find :all,
      :conditions => { :date => Date.today + APP_CONFIG[:occasion_reminder_days] },
      :include => :event

    occasions.each do |occasion|
      occasion.companions.each do |companion|
        OccasionMailer.deliver_reminder_email(occasion, companion)
      end
    end
  end

  desc "Sends a link to occasions' evaluation forms to the companion"
  task(:send_answer_forms => :environment) do
    occasions = Occasion.find :all,
      :conditions => { :date => Date.today - APP_CONFIG[:evaluation_form][:activation_days] },
      :include => :event
    
    occasions.each do |occasion|
      occasion.companions.each do |companion|
        if companion.answer_form
          OccasionMailer.deliver_answer_form_email(occasion, companion)
        end
      end
    end
  end

  desc "Reminds a companion to fill in the evaluation form"
  task(:remind_answer_form => :environment) do
    answer_forms = AnswerForm.find_overdue(Date.today - APP_CONFIG[:evaluation_form][:reminder_days])

    answer_forms.each do |answer_form|
      OccasionMailer.deliver_answer_form_reminder_email(answer_form)
    end
  end
end
