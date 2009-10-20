require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "main image" do
    ev = Event.find events(:pyjamassanger).id
    assert_equal ev.main_image.id, images(:pyjamassanger_logo).id
  end

  test "images excluding main" do
    ev = Event.find events(:pyjamassanger).id
    imgs = ev.images_excluding_main

    assert !imgs.empty?

    imgs.each do |img|
      assert_equal img.event_id, ev.id
      assert_equal img.id, images(:pyjamassanger_img1).id
    end
  end

  test "bookable" do
    ev = Event.find(events(:gula_museet_bookable).id)
    assert ev.bookable?
    
    # visible_from
    ev.visible_from = Date.today + 2
    ev.visible_to = Date.today + 4
    assert !ev.bookable?(true)
    ev.reload

    # visible_to
    ev.visible_from = Date.today - 4
    ev.visible_to = Date.today - 2
    assert !ev.bookable?(true)
    ev.reload

    # ticket_release_date
    ev.ticket_release_date = Date.today + 2
    assert !ev.bookable?(true)
    ev.reload

    # No tickets
    assert !Event.find(events(:pyjamassanger).id).bookable?

    # No occasions
    assert !Event.find(events(:grona_teatern_standing).id).bookable?
  end

  test "find without tickets" do
    es = Event.without_tickets.find :all
    es.each { |e| assert e.tickets.empty? }
  end

  test "not targeted group ids" do
    e = Event.find(events(:pyjamassanger).id)
    ids = e.not_targeted_group_ids
    assert_equal 1, ids.length
    assert_equal groups(:centrumskolan2_klass6).id, ids[0]
  end

  test "ticket usage" do
    e = Event.find(events(:pyjamassanger).id)
    assert_equal [2, 1], e.ticket_usage
  end

  test "further education set" do
    Event.delete_observers
    e = Event.new
    e.name = "x"
    e.description = "x"
    e.from_age = 10
    e.to_age = 11
    e.visible_from = Date.today
    e.visible_to = Date.today + 1
    e.further_education = true

    e.save
    assert_equal -1, e.from_age
    assert_equal -1, e.to_age
  end

end
