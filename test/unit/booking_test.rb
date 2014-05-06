# -*- encoding : utf-8 -*-
require_relative '../test_helper'

class BookingTest < ActiveSupport::TestCase
  test "validations" do
    booking = build(:booking, group: nil)
    assert !booking.valid?
    assert booking.errors.include?(:group)
    booking = build(:booking, occasion: nil)
    assert !booking.valid?
    assert booking.errors.include?(:occasion)
    booking = build(:booking, user: nil)
    assert !booking.valid?
    assert booking.errors.include?(:user)
    booking = build(:booking, companion_name: nil)
    assert !booking.valid?
    assert booking.errors.include?(:companion_name)
    booking = build(:booking, companion_email: nil)
    assert !booking.valid?
    assert booking.errors.include?(:companion_email)
    booking = build(:booking, companion_phone: nil)
    assert !booking.valid?
    assert booking.errors.include?(:companion_phone)
    booking = build(:booking, bus_stop: nil, bus_booking: true)
    assert !booking.valid?
    assert booking.errors.include?(:bus_stop)
  end
  test "validate seats" do
    ## New booking
    # No seats
    booking = build(:booking, student_count: 0, adult_count: 0, wheelchair_count: 0)
    assert !booking.valid?
    assert_equal "Du måste boka minst 1 plats", booking.errors[:student_count].first

    # Too few available tickets
    booking = build(:booking, student_count: 1, adult_count: 0, wheelchair_count: 0, skip_tickets: true)
    assert !booking.valid?
    assert_equal "Du har bara 0 platser du kan boka på den här föreställningen", booking.errors[:student_count].first

    # Too few seats
    occasion = create(:occasion, seats: 10, wheelchair_seats: 3)
    booking = build(:booking, occasion: occasion, student_count: 20, adult_count: 0, wheelchair_count: 0)
    assert !booking.valid?
    assert_equal "Du har bara 13 platser du kan boka på den här föreställningen", booking.errors[:student_count].first

    # Too few wheelchair seats
    booking = build(:booking, occasion: occasion, student_count: 1, adult_count: 0, wheelchair_count: 4)
    assert !booking.valid?
    assert_equal "Det finns bara 3 rullstolsplatser du kan boka på den här föreställningen", booking.errors[:wheelchair_count].first

    # Wheelchair seats already booked
    create_list(:ticket, 2, occasion: occasion, wheelchair: true, state: :booked)
    booking = build(:booking, occasion: occasion, student_count: 1, adult_count: 0, wheelchair_count: 2)
    assert !booking.valid?
    assert_equal "Det finns bara 1 rullstolsplatser du kan boka på den här föreställningen", booking.errors[:wheelchair_count].first

    ## Existing booking
    # No seats
    booking = create(:booking)
    assert booking.valid?
    booking.student_count    = 0
    booking.adult_count      = 0
    booking.wheelchair_count = 0
    assert !booking.valid?
    assert_equal "Du måste boka minst 1 plats", booking.errors[:student_count].first

    # Too few tickets
    booking = create(:booking)
    assert booking.valid?
    booking.student_count += 1
    assert !booking.valid?
    assert_equal "Du har bara 0 platser du kan boka på den här föreställningen", booking.errors[:student_count].first

    # Too few seats
    occasion = create(:occasion, seats: 10, wheelchair_seats: 0)
    booking = create(:booking, occasion: occasion, student_count: 8, adult_count: 2, wheelchair_count: 0)
    assert booking.valid?
    create(:ticket, event: occasion.event, group: booking.group, state: :unbooked, wheelchair: false)
    booking.student_count += 1
    assert !booking.valid?
    assert_equal "Du har bara 0 platser du kan boka på den här föreställningen", booking.errors[:student_count].first

    # Too few wheelchair seats
    occasion = create(:occasion, seats: 10, wheelchair_seats: 0)
    booking = create(:booking, occasion: occasion, student_count: 8, adult_count: 2, wheelchair_count: 0)
    assert booking.valid?
    create(:ticket, event: occasion.event, group: booking.group, state: :unbooked, wheelchair: false)
    booking.wheelchair_count += 1
    assert !booking.valid?
    assert_equal "Det finns bara 0 rullstolsplatser du kan boka på den här föreställningen", booking.errors[:wheelchair_count].first

    # Wheelchair seats already booked
    occasion = create(:occasion, seats: 10, wheelchair_seats: 2)
    booking = create(:booking, occasion: occasion, student_count: 8, adult_count: 2, wheelchair_count: 0)
    create_list(:ticket, 2, occasion: occasion, wheelchair: true, state: :booked)
    assert booking.valid?
    create(:ticket, event: occasion.event, group: booking.group, state: :unbooked, wheelchair: false)
    booking.wheelchair_count += 1
    assert !booking.valid?
    assert_equal "Det finns bara 0 rullstolsplatser du kan boka på den här föreställningen", booking.errors[:wheelchair_count].first

    # Include deactivated tickets in the validation, for group allotment
    occasion = create(:occasion, single_group: true)
    booking = create(:booking, occasion: occasion)
    create(:ticket, event: occasion.event, group: booking.group, state: :deactivated, booking: booking)
    booking.tickets(true) # reload association
    assert booking.valid?
    booking.student_count += 2
    assert !booking.valid?
    assert_equal "Du har bara 1 platser du kan boka på den här föreställningen", booking.errors[:student_count].first

    # Include deactivated tickets in the validation, the other allotment states
    occasion = create(:occasion, single_group: true)
    occasion.event.ticket_state = :alloted_district
    booking = create(:booking, occasion: occasion)
    create(:ticket, event: occasion.event, group: booking.group, state: :deactivated, booking: booking)
    booking.tickets(true) # reload association
    assert booking.valid?
    booking.student_count += 2
    assert !booking.valid?
    assert_equal "Du har bara 1 platser du kan boka på den här föreställningen", booking.errors[:student_count].first
  end

  test "synchronize tickets - normal occasion" do
    assert !Ticket.exists?
    booking = build(:booking, student_count: 15, adult_count: 3, wheelchair_count: 2)
    assert_equal 20, Ticket.count(:all)
    Ticket.all.each { |t| assert t.unbooked? }

    # New booking
    booking.save!
    booking.tickets(true)
    Ticket.all.each { |t| assert t.booked? }
    assert_equal booking.student_count,    Ticket.where(adult: false, wheelchair: false).count
    assert_equal booking.adult_count,      Ticket.where(adult: true,  wheelchair: false).count
    assert_equal booking.wheelchair_count, Ticket.where(adult: false, wheelchair: true ).count


    # Existing booking, fewer tickets
    booking.student_count    -= 1
    booking.adult_count      -= 1
    booking.wheelchair_count -= 1

    booking.save!
    booking.tickets(true)
    assert_equal 3,                        Ticket.unbooked.count
    assert_equal booking.student_count,    Ticket.booked.where(adult: false, wheelchair: false).count
    assert_equal booking.adult_count,      Ticket.booked.where(adult: true,  wheelchair: false).count
    assert_equal booking.wheelchair_count, Ticket.booked.where(adult: false, wheelchair: true ).count

    # Existing booking, more tickets
    booking.student_count    += 1
    booking.adult_count      += 1
    booking.wheelchair_count += 1

    booking.save!
    booking.tickets(true)
    Ticket.all.each { |t| assert t.booked? }
    assert_equal booking.student_count,    Ticket.where(adult: false, wheelchair: false).count
    assert_equal booking.adult_count,      Ticket.where(adult: true,  wheelchair: false).count
    assert_equal booking.wheelchair_count, Ticket.where(adult: false, wheelchair: true).count

    # Unbook
    booking.unbooked = true
    booking.save!
    Ticket.all.each { |t| assert t.unbooked? }
  end

  test "synchronize tickets - single group occasion" do
    assert !Ticket.exists?
    occasion = create(:occasion, single_group: true)
    booking = build(:booking, occasion: occasion, student_count: 15, adult_count: 3, wheelchair_count: 2)
    create_list(
      :ticket,
      10,
      booking: nil,
      group: booking.group,
      district: booking.group.school.district,
      occasion: booking.occasion,
      event: booking.occasion.event,
      state: :unbooked
    )
    assert_equal 30, Ticket.count(:all)
    Ticket.all.each { |t| assert t.unbooked? }

    # New booking
    booking.save!
    booking.tickets(true)
    assert_equal 20,                       Ticket.booked.count
    assert_equal 10,                       Ticket.deactivated.count
    assert_equal booking.student_count,    Ticket.booked.where(adult: false, wheelchair: false).count
    assert_equal booking.adult_count,      Ticket.booked.where(adult: true,  wheelchair: false).count
    assert_equal booking.wheelchair_count, Ticket.booked.where(adult: false, wheelchair: true).count


    ## Existing booking, fewer tickets
    booking.student_count    -= 1
    booking.adult_count      -= 1
    booking.wheelchair_count -= 1

    booking.save!
    booking.tickets(true)
    assert_equal 17,                       Ticket.booked.count
    assert_equal 13,                       Ticket.deactivated.count
    assert_equal booking.student_count,    Ticket.booked.where(adult: false, wheelchair: false).count
    assert_equal booking.adult_count,      Ticket.booked.where(adult: true,  wheelchair: false).count
    assert_equal booking.wheelchair_count, Ticket.booked.where(adult: false, wheelchair: true).count

    ## Existing booking, more tickets
    booking.student_count    += 2
    booking.adult_count      += 2
    booking.wheelchair_count += 2

    booking.save!
    booking.tickets(true)
    assert_equal 23,                       Ticket.booked.count
    assert_equal 7,                        Ticket.deactivated.count
    assert_equal booking.student_count,    Ticket.booked.where(adult: false, wheelchair: false).count
    assert_equal booking.adult_count,      Ticket.booked.where(adult: true,  wheelchair: false).count
    assert_equal booking.wheelchair_count, Ticket.booked.where(adult: false, wheelchair: true).count

    # Unbook
    booking.unbooked = true
    booking.save!
    Ticket.all.each { |t| assert t.unbooked? }
  end

  test "set booked at timestamp" do
    booking = build(:booking, booked_at: nil)
    before = Time.now
    assert booking.save
    after = Time.now
    assert_not_nil booking.booked_at
    assert booking.booked_at >= before
    assert booking.booked_at <= after
  end

  test "active" do
    active   = create(:booking, unbooked: false)
    inactive = create(:booking, unbooked: true)

    assert_equal [active], Booking.active.to_a
  end

  test "counts" do
    booking = build(:booking, student_count: nil, adult_count: nil, wheelchair_count: nil)
    assert_equal 0, booking.student_count
    assert_equal 0, booking.adult_count
    assert_equal 0, booking.wheelchair_count
  end

  test "unbook!" do
    user    = create(:user)
    booking = create(:booking, unbooked_by: nil, unbooked_at: nil, unbooked: false, answer_form: create(:answer_form))

    before = Time.now
    booking.unbook!(user)
    after = Time.now

    assert_equal user, booking.unbooked_by
    assert       booking.unbooked_at >= before
    assert       booking.unbooked_at <= after
    assert       booking.unbooked
    assert       booking.answer_form.destroyed?
  end

  test "find for user" do
    booking = create(:booking)
    create(:booking)
    assert_equal [booking], Booking.find_for_user(booking.user, 1)
  end

  test "find for group" do
    booking = create(:booking)
    create(:booking)
    assert_equal [booking], Booking.find_for_group(booking.group, 1)
  end

  test "find for event" do
    booking = create(:booking, unbooked: true)
    create(:booking)
    assert_equal [booking], Booking.find_for_event(booking.occasion.event.id, {}, 1)

    booking = create(:booking, occasion: booking.occasion, unbooked: false)
    assert_equal [booking], Booking.find_for_event(booking.occasion.event.id, {unbooked: false}, 1)

    booking = create(:booking, occasion: booking.occasion, unbooked: false)
    assert_equal [booking], Booking.find_for_event(booking.occasion.event.id, {unbooked: true, district_id: booking.group.school.district.id}, 1)
  end
  
  test "find for occasion" do
    booking = create(:booking, unbooked: true)
    create(:booking)
    assert_equal [booking], Booking.find_for_occasion(booking.occasion.id, {}, 1)

    booking = create(:booking, occasion: booking.occasion, unbooked: false)
    assert_equal [booking], Booking.find_for_occasion(booking.occasion.id, {unbooked: false}, 1)

    booking = create(:booking, occasion: booking.occasion, unbooked: false)
    assert_equal [booking], Booking.find_for_occasion(booking.occasion.id, {unbooked: true, district_id: booking.group.school.district.id}, 1)
  end

  test "bus booking csv" do
    booking = create(
      :booking,
      bus_booking: true,
      bus_stop: "Bus stop",
      bus_one_way: false
    )

    assert_equal(
      "Evenemang\tDatum\tAdress\tStadsdel\tSkola\tGrupp\tMedföljande vuxen\tTelefonnummer\tE-postadress\tAntal platser\tResa\tHållplats\n#{booking.occasion.event.name}\t#{booking.occasion.date.strftime("%Y-%m-%d")} #{booking.occasion.start_time.strftime("%H:%M")}\t#{booking.occasion.address}\t#{booking.group.school.district.name}\t#{booking.group.school.name}\t#{booking.group.name}\t#{booking.companion_name}\t#{booking.companion_phone}\t#{booking.companion_email}\t#{booking.total_count}\tTur och retur\tBus stop\n",
      Booking.bus_booking_csv([booking])
    )
  end
end
