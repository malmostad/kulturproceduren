class SendAnswerForms

  def initialize(today, activation_days)
    @today, @activation_days = today, activation_days
  end

  def run
    occasions = Occasion.find :all,
      :conditions => { :date => @today - @activation_days, :cancelled => false },
      :include => :event
    
    occasions.each do |occasion|
      occasion.bookings.active.each do |booking|
        if booking.answer_form && !booking.answer_form.completed
          OccasionMailer.answer_form_email(occasion, booking).deliver
          puts "Sending mail about evaluation form for #{occasion.event.name}, #{occasion.date} to #{booking.companion_email}"
        end
      end
    end
  end
end