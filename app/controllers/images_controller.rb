class ImagesController < ApplicationController
  
  layout "default"

  before_filter :authenticate, :except => [ :show ]

  def new
     @image = Image.new
  end

  def create
    @image = Image.new(params[:image])

    if @image.save(params[:upload])
      flash[:notice] = "Bilden laddades upp."
      redirect_to @image
    else
      flash[:error] = "Ett fel uppstod när bilden laddades upp"
      redirect_to new_image_url()
    end
  end

  def show
    @image = Image.find(params[:id])
  end

  def index
    @images = Image.all
  end

end
