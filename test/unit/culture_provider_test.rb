require 'test_helper'

class CultureProviderTest < ActiveSupport::TestCase
  test "main image" do
    cp = CultureProvider.find culture_providers(:grona_teatern).id
    assert_equal cp.main_image.id, images(:grona_teatern_logo).id
  end

  test "images excluding main" do
    cp = CultureProvider.find culture_providers(:grona_teatern).id
    imgs = cp.images_excluding_main

    assert !imgs.empty?

    imgs.each do |img|
      assert_equal img.culture_provider_id, cp.id
      assert_equal img.id, images(:grona_teatern_img1).id
    end
  end

  
  test "standing events" do
    cp = CultureProvider.find culture_providers(:grona_teatern).id
    evs = cp.standing_events

    assert !evs.empty?

    evs.each do |ev|
      assert_equal ev.culture_provider_id, cp.id
      assert_equal ev.id, events(:grona_teatern_standing).id
    end
  end

  test "upcoming occasions" do
    cp = CultureProvider.find culture_providers(:grona_teatern).id
    occs = cp.upcoming_occasions

    assert !occs.empty?

    occs.each do |o|
      assert_equal o.event.culture_provider_id, cp.id
      assert_equal o.id, occasions(:pyjamassanger_new).id
    end
  end
end
