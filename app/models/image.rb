require "rubygems"
require "RMagick"

class Image < ActiveRecord::Base

  belongs_to :event
  belongs_to :culture_provider
  
  alias :save_orig  :save

  def save(upload)

    fname =  Image.gen_fname
    File.open(fname, "wb") { |f| f.write(upload['datafile'].read) }
    self.filename = fname
    img = Magick::Image.read( fname ).first
    if img.nil?
      flash[:error] = "Det gick inte så bra ...."
      redirect_to "/"
      return
    end
    img.change_geometry(Magick::Geometry.new(320,240)) {|c,r,i| img.resize!(c,r) }
    img.write(fname)
    img.change_geometry(Magick::Geometry.new(128,128)) {|c,r,i| img.resize!(c,r) }
    img.write(Image.thumb_name(fname))
    save_orig
  end

  #Generates a unique filename

  def image_url
    self.filename.sub("public","")
  end

  def thumb_url
    self.thumb_name.sub("public","")
  end

  def self.gen_fname()
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    tempfname = ""
    (1..15).each { |i| tempfname << chars[rand(chars.size-1)] }
    while (File.exists?("public/images/#{tempfname}.jpg"))
      tempfname << chars[rand(chars.size-1)]
    end
    return "public/images/" + tempfname.to_s + ".jpg"
  end

  def self.thumb_name(img)
    regexp = /public\/images\/(\w+?).jpg/
    if img.is_a? String
      f = img
      img = Image.new
      img.filename = f
    elsif img.is_a? Integer
      img = Image.find(img)
    else
      return nil
    end
    if img.nil?
      return nil
    end
    img.filename =~ regexp
    thumbname = "public/images/thumb." + $1 + ".jpg"
    return thumbname
  end

  def thumb_name
    Image.thumb_name(self.filename)
  end
end
