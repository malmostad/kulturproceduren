# Container class for images associated with different models in the system.
#
# An image consists of two different images, one full size and one thumbnail.
class Image < ActiveRecord::Base

  belongs_to :event
  belongs_to :culture_provider

  attr_accessible :description,
    :filename,
    :width,
    :height,
    :thumb_width,
    :thumb_height,
    :file,
    :event_id,            :event,
    :culture_provider_id, :culture_provider

  validates_presence_of :description,
    message: "Bildtexten får inte vara tom"

  #validates_presence_of :file,
  #  message: "Filnamnet får inte vara tomt"

  after_destroy :cleanup

  attr_accessor :type
  attr_accessor :file

  before_create :process_file


  # Alias after rename name => description in case name is used anywhere
  def name
    self.description
  end

  # Generates the filesystem path to the image file
  def image_path
    "#{Image.path}/#{self.filename}"
  end

  # Generates the URL to the image file
  def image_url
    "#{Image.url}/#{self.filename}"
  end

  # Generates the filesystem path to the thumbnail file
  def thumb_path
    "#{Image.path}/#{self.thumb_name}"
  end

  # Generates the URL to the thumbnail file
  def thumb_url
    "#{Image.url}/#{self.thumb_name}"
  end
  
  # Generates the name for the thumbnail
  def thumb_name
    self.filename.sub(/\.jpg$/, ".thumb.jpg")
  end

  # Generates a random filename for the image and thumbnail.
  def self.generate_filename()
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    tempfname = ""

    (1..15).each { |i| tempfname << chars[rand(chars.size-1)] }
    
    while File.exists?("#{Image.path}/#{tempfname}.jpg")
      tempfname << chars[rand(chars.size-1)]
    end
    
    return tempfname.to_s + ".jpg"
  end

  protected

  # On-destroy callback for deleting the image files.
  def cleanup
    begin
      File.delete image_path
      File.delete thumb_path
    rescue; end
  end

  # Base filesystem path for the image files
  def self.path
    "#{Rails.root}/public/images/#{APP_CONFIG[:upload_image][:path]}"
  end
  # Base URLs for the image files
  def self.url
    "#{APP_CONFIG[:upload_image][:path]}"
  end


  private

  # This method resizes an uploaded image and creates the image's thumbnail
  def process_file
    return false unless valid?
    return true unless self.file

    self.filename = Image.generate_filename
    File.open(self.image_path, "wb") { |f| f.write(self.file.read) }

    img = Magick::Image.read(self.image_path).first

    raise "Could not read the uploaded image." if img.nil?

    img.resize_to_fit!(APP_CONFIG[:upload_image][:width], APP_CONFIG[:upload_image][:height])

    self.width = img.columns
    self.height = img.rows

    img.write(self.image_path)

    img.resize_to_fit!(APP_CONFIG[:upload_image][:thumb_width], APP_CONFIG[:upload_image][:thumb_height])

    self.thumb_width = img.columns
    self.thumb_height = img.rows

    img.write(self.thumb_path)
  end

end
