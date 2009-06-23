class ImagesController < ApplicationController
  
  layout "standard"

  before_filter :authenticate, :except => [ :show ]

  def new
    @image = Image.new { |i| i.type = params[:type] }
    
    if params[:culture_provider_id]
      @image.culture_provider = CultureProvider.find params[:culture_provider_id]
    elsif params[:event_id]
      @image.event = Event.find params[:event_id]
    else
      flash[:error] = "Felaktigt anrop."
      redirect_to "/"
    end
  end

  def create
    @image = Image.new params[:image]
    @image.type = params[:image][:type].to_sym

    if @image.save(params[:upload])

      if @image.culture_provider
        if @image.type == :main
          begin
            @image.culture_provider.main_image.destroy if @image.culture_provider.main_image
          rescue; end

          @image.culture_provider.main_image = @image
          @image.culture_provider.save!
        end

        redirect_to @image.culture_provider
      elsif @image.event
        if @image.type == :main
          begin
            @image.event.main_image.destroy if @image.event.main_image
          rescue; end

          @image.event.main_image = @image
          @image.event.save!
        end

        redirect_to @image.event
      end

      flash[:notice] = "Bilden laddades upp."
    else
      flash.now[:error] = "Fel uppstod när bilden skulle laddas upp."
      render :action => "new"
    end
  end

end
