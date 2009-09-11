# Controller for managing an event's attachments
class AttachmentsController < ApplicationController
  layout "standard"

  before_filter :authenticate
  before_filter :require_culture_worker, :except => :show

  # Lists all attachments belonging to an event, with a form for
  # adding more events
  def index
    @attachment = Attachment.new
    @attachment.event = @event
  end

  # Sends the attachment as a download
  def show
    @attachment = Attachment.find(params[:id])
    filepath = get_filepath(@attachment)

    send_file filepath, :type => @attachment.content_type, :filename => @attachment.filename
  end

  def create
    if !params[:upload] || !params[:upload][:document]
      flash[:warning] = "Du måste välja en fil att ladda upp."
      redirect_to event_attachments_url(@event)
      return
    end

    uploaded_file = params[:upload][:document]

    @attachment = Attachment.new(params[:attachment])
    @attachment.filename = uploaded_file.original_filename
    @attachment.content_type = uploaded_file.content_type
    @attachment.event = @event

    if @attachment.save
      filepath = get_filepath(@attachment)

      File.open(filepath, "w") do |file|
        file.write(uploaded_file.read)
      end

      flash[:notice] = "Lärarhandledningen laddades upp."
      redirect_to event_attachments_url(@event)
    else
      render :action => "index"
    end

  end

  def destroy
    @attachment = Attachment.find(params[:id])
    File.delete get_filepath(@attachment)

    @attachment.destroy

    flash[:notice] = 'Lärarhandlednignen togs bort.'
    redirect_to event_attachments_url(@event)
  end

  private

  def get_filepath(attachment)
    filename = @attachment.id.to_s + File.extname(@attachment.filename)
    return Rails.root.join('public', APP_CONFIG[:upload_attachment][:path], filename)
  end

  # Checks if the user has administration privileges on the occasion.
  # For use in +before_filter+.
  def require_culture_worker
    @event = Event.find(params[:event_id], :include => :culture_provider)

    unless current_user.can_administrate?(@event.culture_provider)
      flash[:error] = "Du har inte behörighet att komma åt sidan."
      redirect_to @event
    end
  rescue
    flash[:error] = "Du måste ange ett giltigt evenemang."
    redirect_to root_url()
  end
end
