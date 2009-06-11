require "rubygems"
require "RMagick"

class Image < ActiveRecord::Base

  belongs_to :event
  belongs_to :culture_provider

  validates_presence_of :name

  after_destroy :cleanup

  attr_accessor :type


  alias :save_orig  :save
  def save(upload)

    return false unless valid?

    self.filename = Image.gen_fname
    File.open(self.image_path, "wb") { |f| f.write(upload['datafile'].read) }
    
    img = Magick::Image.read(self.image_path).first
    
    if img.nil?
      flash[:error] = "Det gick inte så bra ...."
      redirect_to "/"
      return
    end

    img.change_geometry(Magick::Geometry.new(320,240)) {|c,r,i| img.resize!(c,r) }
    img.write(self.image_path)

    img.change_geometry(Magick::Geometry.new(128,128)) {|c,r,i| img.resize!(c,r) }
    img.write(self.thumb_path)
    
    save_orig
  end

  def thumb_name
    Image.thumb_name(self.filename)
  end

  def image_path
    "#{RAILS_ROOT}/public/#{APP_CONFIG[:upload_image_path]}/#{self.filename}"
  end

  def image_url
    "/#{APP_CONFIG[:upload_image_path]}/#{self.filename}"
  end

  def thumb_path
    "#{RAILS_ROOT}/public/#{APP_CONFIG[:upload_image_path]}/#{Image.thumb_name(self.filename)}"
  end

  def thumb_url
    "/#{APP_CONFIG[:upload_image_path]}/#{self.thumb_name}"
  end
  

  def self.gen_fname()
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    tempfname = ""

    (1..15).each { |i| tempfname << chars[rand(chars.size-1)] }
    
    while File.exists?("#{RAILS_ROOT}/public/#{APP_CONFIG[:upload_image_path]}/#{tempfname}.jpg")
      tempfname << chars[rand(chars.size-1)]
    end
    
    return tempfname.to_s + ".jpg"
  end

  def self.thumb_name(img)
    regexp = /(\w+?).jpg$/

    if img.is_a? String
      img = Image.new { |i| i.filename = img }
    elsif img.is_a? Integer
      img = Image.find(img)
    else
      return nil
    end
    
    return nil if img.nil?

    img.filename =~ regexp
    return $1 + ".thumb.jpg"
  end

  protected

  def cleanup
    begin
      File.delete image_path
      File.delete thumb_path
    rescue; end
  end

end
