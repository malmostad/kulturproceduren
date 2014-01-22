# -*- encoding : utf-8 -*-
require 'test_helper'

class DistrictTest < ActiveSupport::TestCase
  test "validations" do
    district = build(:district, :name => "")
    assert !district.valid?
    assert district.errors.include?(:name)
  end

  test "schools by age span" do
    district = create(:district)
    create(:district_with_age_groups) # dummy

    forskola = create(:school, :district => district)
    create(:group_with_age_groups, :school => forskola, :age_group_data => [[3, 1], [4, 1]])
    create(:group_with_age_groups, :school => forskola, :age_group_data => [[5, 1], [6, 1]])
    create(:group_with_age_groups, :school => forskola, :age_group_data => [[1, 1]], :active => false)

    lagstadie = create(:school, :district => district)
    create(:group_with_age_groups, :school => lagstadie, :age_group_data => [[7, 1]])
    create(:group_with_age_groups, :school => lagstadie, :age_group_data => [[8, 1]])
    create(:group_with_age_groups, :school => lagstadie, :age_group_data => [[9, 1]])
    create(:group_with_age_groups, :school => lagstadie, :age_group_data => [[1, 1]], :active => false)

    mellanstadie = create(:school, :district => district)
    create(:group_with_age_groups, :school => mellanstadie, :age_group_data => [[10, 1]])
    create(:group_with_age_groups, :school => mellanstadie, :age_group_data => [[11, 1]])
    create(:group_with_age_groups, :school => mellanstadie, :age_group_data => [[12, 1]])
    create(:group_with_age_groups, :school => mellanstadie, :age_group_data => [[1, 1]], :active => false)

    schools = district.schools.find_by_age_span(8, 11)
    assert !schools.blank?
    schools.each { |s| assert s.age_groups.exists?(:age => (8..11)) }

    schools = district.schools.find_by_age_span(6, 7)
    assert !schools.blank?
    schools.each { |s| assert s.age_groups.exists?(:age => (6..7)) }

    # active
    assert district.schools.find_by_age_span(1, 2).blank?
  end

  test "available tickets by occasion" do
    occasion = create(:occasion)
    district = create(:district)
    create_list(:ticket, 5, :event => occasion.event, :district => district, :state => :unbooked)
    create_list(:ticket, 5, :event => occasion.event, :district => district, :state => :booked)
    create_list(:ticket, 5, :event => occasion.event, :state => :unbooked)
    create_list(:ticket, 5, :event => occasion.event, :state => :booked)

    occasion.event.ticket_state = :alloted_group
    occasion.event.save!
    assert_equal 5, district.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :alloted_district
    occasion.event.save!
    assert_equal 5, district.available_tickets_by_occasion(occasion)
    occasion.event.ticket_state = :free_for_all
    occasion.event.save!
    assert_equal 10, district.available_tickets_by_occasion(occasion)
  end

end
