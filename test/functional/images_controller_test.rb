# -*- encoding : utf-8 -*-
require 'test_helper'

class ImagesControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  test "index, wrong parameters" do
    get :index
    assert_redirected_to root_url()
    assert_equal         "Felaktigt anrop.", flash[:error]
  end
  test "index, culture provider" do
    culture_provider = create(:culture_provider)
    images           = create_list(:image, 2, :culture_provider => culture_provider)

    get :index, :culture_provider_id => culture_provider.id

    assert_response :success
    assert          assigns(:image).new_record?
    assert_equal    culture_provider, assigns(:image).culture_provider
    assert_equal    images,           assigns(:images)
  end
  test "index, event" do
    event  = create(:event)
    images = create_list(:image, 2, :event => event)

    get :index, :event_id => event.id

    assert_response :success
    assert          assigns(:image).new_record?
    assert_equal    event,  assigns(:image).event
    assert_equal    images, assigns(:images)
  end

  test "set main" do
    culture_provider = create(:culture_provider)
    images           = create_list(:image, 2, :culture_provider => culture_provider)

    culture_provider.main_image = images.first
    culture_provider.save!

    get :set_main, :culture_provider_id => culture_provider.id, :id => images.last.id
    assert_redirected_to culture_provider_images_url(culture_provider)
    assert_equal         images.last, CultureProvider.find(culture_provider.id).main_image(true)
  end

  test "create, wrong parameters" do
    post :create
    assert_redirected_to root_url()
    assert_equal         "Felaktigt anrop.", flash[:error]
  end
  def stub_rmagick!
    magick = stub(:columns => 20, :rows => 21)
    Magick::Image.stubs(:read).returns([magick])
    magick.stubs(:resize_to_fit!).returns(true)
    magick.stubs(:write).returns(true)
  end
  test "create, culture provider" do
    File.stubs(:open)
    old_app_config = APP_CONFIG
    Kernel::silence_warnings { ::APP_CONFIG = { :upload_image => { :width => 10, :height => 20, :thumb_width => 1, :thumb_height => 2 } } }
    stub_rmagick!
    upload = { "datafile" => stub(:read => "foo") }

    culture_provider = create(:culture_provider)

    # Invalid
    post :create, :culture_provider_id => culture_provider.id, :upload => upload, :image => { :description => "" }
    assert_response :success
    assert_template "images/index"
    assert          !assigns(:image).valid?

    # Valid
    post :create, :culture_provider_id => culture_provider.id, :upload => upload, :image => { :description => "foo" }

    image = Image.last
    assert_redirected_to culture_provider_images_url(culture_provider)
    assert_equal         "Bilden laddades upp.", flash[:notice]
    assert_equal         culture_provider,       image.culture_provider
    assert_equal         "foo",                  image.description

    Kernel::silence_warnings { ::APP_CONFIG = old_app_config }
  end
  test "create, event" do
    File.stubs(:open)
    old_app_config = APP_CONFIG
    Kernel::silence_warnings { ::APP_CONFIG = { :upload_image => { :width => 10, :height => 20, :thumb_width => 1, :thumb_height => 2 } } }
    stub_rmagick!
    upload = { "datafile" => stub(:read => "foo") }

    event = create(:event)

    # Invalid
    post :create, :event_id => event.id, :upload => upload, :image => { :description => "" }
    assert_response :success
    assert_template "images/index"
    assert          !assigns(:image).valid?

    # Valid
    post :create, :event_id => event.id, :upload => upload, :image => { :description => "foo" }

    image = Image.last
    assert_redirected_to event_images_url(event)
    assert_equal         "Bilden laddades upp.", flash[:notice]
    assert_equal         event,                  image.event
    assert_equal         "foo",                  image.description

    Kernel::silence_warnings { ::APP_CONFIG = old_app_config }
  end

  test "destroy, culture provider" do
    File.stubs(:delete)

    culture_provider = create(:culture_provider)
    image            = create(:image, :culture_provider => culture_provider, :event => nil)
    main_image       = create(:image, :culture_provider => culture_provider, :event => nil)

    culture_provider.main_image = main_image
    culture_provider.save!

    delete :destroy, :id => image.id
    assert_redirected_to culture_provider_images_url(culture_provider)
    assert_equal         "Bilden togs bort", flash[:notice]
    assert_nil           Image.first(:conditions => { :id => image.id })
    assert_equal         main_image, CultureProvider.find(culture_provider.id).main_image

    delete :destroy, :id => main_image.id
    assert_nil CultureProvider.find(culture_provider.id).main_image
  end
  test "destroy, event" do
    File.stubs(:delete)
    event = create(:event)
    image = create(:image, :event => event, :culture_provider => nil)

    delete :destroy, :id => image.id
    assert_redirected_to event_images_url(event)
    assert_equal         "Bilden togs bort", flash[:notice]
    assert_nil           Image.first(:conditions => { :id => image.id })
  end
end
