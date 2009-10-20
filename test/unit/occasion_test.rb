require 'test_helper'

class OccasionTest < ActiveSupport::TestCase
  
  test "attending groups" do
    o = Occasion.find(occasions(:pyjamassanger_new))
    assert_equal 1, o.attending_groups.count
    assert_equal groups(:centrumskolan1_klass35).id, o.attending_groups[0].id
  end

  test "ticket usage" do
    o = Occasion.find(occasions(:pyjamassanger_new))
    assert_equal [2, 1], o.ticket_usage
  end

  test "available wheelchair seats" do
    o = Occasion.find(occasions(:pyjamassanger_new))
    assert_equal 1, o.available_wheelchair_seats
  end

  test "available seats" do
    o = Occasion.find(occasions(:pyjamassanger_new))
    assert_equal 3, o.available_seats
  end
end
