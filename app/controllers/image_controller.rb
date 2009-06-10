class ImageController < ApplicationController
  def new
     @image = Image.new
  end
  def create
    @image = Image.new(params[:image])
    @image.save(params[:upload])
    render :text => "File has been uploaded successfully"
  end
  def show
    @image = Image.find(params[:id])
  end
  def index
    @images = Image.all
  end
end
