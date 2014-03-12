class RemindAnswerForm

  def initialize(today, reminder_days)
    @today, @reminder_days = today, reminder_days
  end


  def run
    answer_forms = AnswerForm.find_overdue(@today - @reminder_days)

    answer_forms.each do |answer_form|
      OccasionMailer.answer_form_reminder_email(answer_form).deliver
      puts "Sending reminder mail about evaluation form for #{answer_form.occasion.event.name}, #{answer_form.occasion.date} to #{answer_form.booking.companion_email}"
    end
  end
end