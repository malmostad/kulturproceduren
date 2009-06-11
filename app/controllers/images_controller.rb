class ImagesController < ApplicationController
  
  layout "standard"

  before_filter :authenticate, :except => [ :show ]

  def new
    @image = Image.new { |i| i.type = params[:type] }
    
    if params[:culture_provider_id]
      @image.culture_provider = CultureProvider.find params[:culture_provider_id]
    else
      flash[:error] = "Felaktigt anrop."
      redirect_to "/"
    end
  end

  def create
    @image = Image.new params[:image]

    if @image.save(params[:upload])

      if @image.culture_provider
        if params[:image][:type].to_sym == :main
          begin
            @image.culture_provider.main_image.destroy if @image.culture_provider.main_image
          rescue; end

          @image.culture_provider.main_image = @image
          @image.culture_provider.save!
        end

        redirect_to @image.culture_provider
      end

      flash[:notice] = "Bilden laddades upp."
    else
      @image.type = params[:image][:type].to_sym
      render :action => "new"
    end
  end

end
