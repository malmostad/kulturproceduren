class InformationController < ApplicationController
  layout "admin"

  before_filter :authenticate
  before_filter :require_admin

  def new
    @mail = UtilityModels::InformationMail.new
    if params[:event_id]
      @event = Event.find(params[:event_id])
      @mail.recipients = @event.id
    end
  end

  def create
    @mail = UtilityModels::InformationMail.new(params[:information_mail])

    if @mail.valid?
      recipients = @mail.recipient_addresses

      recipients.each do |r|
        InformationMailer.custom_email(r, @mail.subject, @mail.body).deliver
      end
      
      notice = case @mail.recipients
      when :all_contacts
        "alla kontakter"
      when :all_users
        "alla användare"
      else
        "alla bokade till #{@mail.event.name}"
      end

      flash[:notice] = "E-post skickat till #{notice} (#{recipients.length} mottagare)"
      redirect_to :action => :new
    else
      render :action => :new
    end

  end
end
