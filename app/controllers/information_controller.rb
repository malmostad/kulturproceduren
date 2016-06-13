class InformationController < ApplicationController
  layout "application"

  before_filter :authenticate
  before_filter :require_admin

  def new
    @mail = UtilityModels::InformationMail.new params
    @event = Event.find(params[:event_id]) if params[:event_id]

    if @mail.recipients == :all_alloted
      render 'new_for_all_alloted'
    elsif @mail.recipients == :all_booked
      render 'new_for_all_booked'
    end
  end

  def create
    @mail = UtilityModels::InformationMail.new(params[:information_mail])

    if @mail.valid?
      recipients = @mail.recipient_addresses

      recipients.each do |r|
        InformationMailer.custom_email(r, @mail.subject, @mail.body).deliver
      end
      
      notice =
        case @mail.recipients
        when :all_alloted
         "alla fördelade för #{@mail.event.name}"
        when :all_booked
          "alla bokade till #{@mail.event.name}"
        when :all_contacts
          'alla kontakter'
        when :all_users
          'alla användare'
        else
          ''
        end

      flash[:notice] = "E-post skickat till #{notice} (#{recipients.length} mottagare)"
      redirect_to action: :new, recipients: @mail.recipients, event_id: @mail.event_id
    else
      if @mail.recipients == :all_alloted
        render 'new_for_all_alloted'
      elsif @mail.recipients == :all_booked
        render 'new_for_all_booked'
      else
        render action: :new
      end
    end

  end
end
