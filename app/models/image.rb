require "rubygems"
require "RMagick"

class Image < ActiveRecord::Base

  belongs_to :event
  belongs_to :culture_provider
  
  alias :save_orig  :save

  def save(upload)

    filename = Image.gen_fname
    File.open(filename, "wb") { |f| f.write(upload['datafile'].read) }
    
    img = Magick::Image.read( filename ).first
    
    if img.nil?
      flash[:error] = "Det gick inte så bra ...."
      redirect_to "/"
      return
    end

    img.change_geometry(Magick::Geometry.new(320,240)) {|c,r,i| img.resize!(c,r) }
    img.write("#{RAILS_ROOT}/public/#{APP_CONFIG[:upload_image_path]}/#{filename}")

    img.change_geometry(Magick::Geometry.new(128,128)) {|c,r,i| img.resize!(c,r) }
    img.write("#{RAILS_ROOT}/public/#{APP_CONFIG[:upload_image_path]}/#{Image.thumb_name(filename)}")
    
    save_orig
  end

  def image_url
    "#{APP_CONFIG[:upload_image_path]}/#{filename}"
  end

  def thumb_url
    "#{APP_CONFIG[:upload_image_path]}/#{thumb_name}"
  end

  def self.gen_fname()
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    tempfname = ""

    (1..15).each { |i| tempfname << chars[rand(chars.size-1)] }
    
    while (File.exists?("#{RAILS_ROOT}/public/#{APP_CONFIG[:upload_image_path]}/#{tempfname}.jpg"))
      tempfname << chars[rand(chars.size-1)]
    end
    
    return tempfname.to_s + ".jpg"
  end

  def self.thumb_name(img)
    regexp = /\/(\w+?).jpg$/

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
    return "thumb." + $1 + ".jpg"
  end

  def thumb_name
    Image.thumb_name(self.filename)
  end
end
