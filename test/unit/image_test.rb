require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  test "validations" do
    image = build(:image, :description => "")
    assert !image.valid?
    assert_not_nil image.errors.on(:description)
  end

  test "save" do
    APP_CONFIG.replace(:upload_image => { :width => 10, :height => 20, :thumb_width => 1, :thumb_height => 2 })

    outfile = "#{RAILS_ROOT}/tmp/foo.txt"
    upload = { "datafile" => stub(:read => "foo") }
    magick = stub(:columns => 20, :rows => 21)
    magick.expects(:resize_to_fit!).with(10, 20).returns(true)
    magick.expects(:resize_to_fit!).with(1, 2).returns(true)
    magick.expects(:write).with(outfile).returns(true)
    magick.expects(:write).with(outfile + ".thumb").returns(true)

    image = Image.new(:description => "foo")

    image.stubs(:image_path).returns(outfile)
    image.stubs(:thumb_path).returns(outfile + ".thumb")
    Magick::Image.stubs(:read).returns([magick])

    image.save(upload)

    assert File.exists?(outfile)

    # Cleanup
    File.delete(outfile)
  end

  test "image path" do
    APP_CONFIG.replace(:upload_image => { :path => "upload" })

    image = create(:image, :filename => "test.jpg")
    assert_equal "#{RAILS_ROOT}/public/images/upload/test.jpg", image.image_path
  end
  test "image url" do
    APP_CONFIG.replace(:upload_image => { :path => "upload" })

    image = create(:image, :filename => "test.jpg")
    assert_equal "upload/test.jpg", image.image_url
  end
  test "thumb path" do
    APP_CONFIG.replace(:upload_image => { :path => "upload" })

    image = create(:image, :filename => "test.jpg")
    assert_equal "#{RAILS_ROOT}/public/images/upload/test.thumb.jpg", image.thumb_path
  end
  test "thumb url" do
    APP_CONFIG.replace(:upload_image => { :path => "upload" })

    image = create(:image, :filename => "test.jpg")
    assert_equal "upload/test.thumb.jpg", image.thumb_url
  end

  test "thumb name" do
    image = create(:image, :filename => "test.jpg")
    assert_equal "test.thumb.jpg", image.thumb_name
  end

  test "generate filename" do
    generated = Image.generate_filename
    assert generated =~ /^[A-Za-z0-9]{15}.jpg$/
  end
end
