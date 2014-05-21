# Cleanup rake tasks
namespace :kp do
  namespace :cleanup do

    desc "Purges all data transient in a school year"
    task(purge: :environment) do
      return if Rails.env.production?
      puts "WARNING: This removes the following data:\n"
      puts " * AgeGroups belonging to inactive groups"
      puts " * Allotments"
      puts " * Answers"
      puts " * AnswerForms"
      puts " * Attachments belonging non-standing Events"
      puts " * Bookings"
      puts " * BookingRequirements"
      puts " * Companions"
      puts " * Non-standing Events"
      puts " * Inactive groups"
      puts " * Images belonging to non-standing Events"
      puts " * NotificationRequests"
      puts " * Occasions"
      puts " * Non-template Questions belonging to non-standing Events"
      puts " * Questionnaires belonging to non-standing Events"
      puts " * Tickets"
      puts

      quit_received = false

      while !quit_received
        puts "Enter today's date to continue (YYYY-MM-DD) or q to quit:"
        user_input = STDIN.gets.chomp

        begin
          if user_input == "q"
            puts "Quitting..."
            quit_received = true
          elsif Date.parse(user_input) == Date.today
            puts "Purging data!"
            quit_received = true

            purge_data()
          end
        rescue ArgumentError
          puts "Input error!"
        end
      end
    end


    private

    def purge_data
      puts "Removing BookingRequirements"
      BookingRequirement.destroy_all
      puts "Removing tickets"
      Ticket.delete_all # No dependencies, so we can delete rather than destroy
      puts "Removing bookings"
      Booking.destroy_all
      puts "Removing allotments"
      Allotment.destroy_all
      puts "Removing AnswerForms and Answers"
      AnswerForm.destroy_all
      puts "Removing NotificationRequests"
      NotificationRequest.destroy_all
      puts "Removing non-standing events and associated Occasions, Questionnaires, Attachments, Images"
      Event.non_standing.all.each { |e| e.destroy }
      puts "Removing inactive Groups with associated AgeGroups"
      Group.all(conditions: { active: false }).each { |g| g.destroy }
      puts "Removing orphaned Questions"
      Question.all(conditions: "template = false and id not in (select question_id from questionnaires_questions)").each { |q| q.destroy }
    end

  end
end
