require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  test "generated filename" do
    assert_match /^[A-Za-z0-9]{15}.jpg$/, Image.gen_fname()
  end

  test "thumbnail name" do
    filename = Image.gen_fname()
    assert_equal filename.split(".")[0] + ".thumb.jpg", Image.thumb_name(filename)
  end

  test "paths" do
    image = Image.new
    image.filename = Image.gen_fname()

    assert_equal "#{APP_CONFIG[:upload_image][:path]}/#{image.filename}", image.image_url
    assert_equal "#{APP_CONFIG[:upload_image][:path]}/#{Image.thumb_name(image.filename)}", image.thumb_url
    assert_equal "#{RAILS_ROOT}/public/images/#{APP_CONFIG[:upload_image][:path]}/#{image.filename}", image.image_path
    assert_equal "#{RAILS_ROOT}/public/images/#{APP_CONFIG[:upload_image][:path]}/#{Image.thumb_name(image.filename)}", image.thumb_path
  end
end
