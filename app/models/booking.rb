require "csv"

class Booking < ActiveRecord::Base
  belongs_to :group
  belongs_to :occasion
  has_one :event, through: :occasion
  belongs_to :user
  belongs_to :unbooked_by, class_name: "User", foreign_key: "unbooked_by_id"

  has_many :tickets
  has_one :answer_form

  attr_accessible :unbooked,
    :unbooked_by_id,   :unbooked_by,
    :student_count,
    :adult_count,
    :wheelchair_count,
    :requirement,
    :companion_name,
    :companion_phone,
    :companion_email,
    :group_id,         :group,
    :occasion_id,      :occasion,
    :user_id,          :user,
    :bus_booking,
    :bus_one_way,
    :bus_stop

  validates_presence_of :group, message: "Bokningen måste tillhöra en grupp"
  validates_presence_of :occasion, message: "Bokningen måste tillhöra en föreställning"
  validates_presence_of :user, message: "Bokningen måste tillhöra en användare"

  validate :validate_seats

  validates_presence_of :companion_name, message: "Namnet får inte vara tomt"
  validates_presence_of :companion_email, message: "Epostadressen får inte vara tom"
  validates_presence_of :companion_phone, message: "Telefonnumret får inte vara tomt"

  validates_presence_of :bus_stop, if: :bus_booking, message: "Du måste ange en hållplats"

  after_save :synchronize_tickets
  before_create :set_booked_at_timestamp

  scope :active, lambda{ where(unbooked: false) }

  def student_count
    read_attribute(:student_count).to_i
  end
  def adult_count
    read_attribute(:adult_count).to_i
  end
  def wheelchair_count
    read_attribute(:wheelchair_count).to_i
  end

  def total_count
    self.student_count + self.adult_count + self.wheelchair_count
  end

  def synchronize_tickets
    if !self.unbooked
      bookable_tickets = self.tickets + self.group.bookable_tickets(self.occasion, true)

      unless bookable_tickets.blank?
        book_tickets(bookable_tickets, :normal, self.student_count)
        book_tickets(bookable_tickets, :adult, self.adult_count)
        book_tickets(bookable_tickets, :wheelchair, self.wheelchair_count)

        if self.occasion.single_group
          num_deactivate = self.occasion.seats.to_i + self.occasion.wheelchair_seats.to_i - self.total_count
          book_tickets(bookable_tickets, :normal, num_deactivate, :deactivated)
        else
          bookable_tickets.each { |ticket| ticket.unbook! }
        end

      end
    else
      self.tickets.each { |ticket| ticket.unbook! }
    end
  end

  def unbook!(user)
    self.unbooked_by = user
    self.unbooked_at = Time.zone.now
    self.unbooked = true
    self.save!
    self.answer_form.try(:destroy)
  end


  def self.find_for_user(user, filter, page)
    conditions = [ "bookings.user_id = ?", user.id ]
    apply_filter(conditions, filter)

    self.includes(occasion: :event, group: :school)
      .where(conditions[0], *conditions[1..-1])
      .order("occasions.date desc, group_id desc")
      .paginate(page: page)
  end

  def self.find_for_group(group, page)
    self.includes(:occasion)
      .where(group_id: group.id)
      .order("occasions.date desc")
      .paginate(page: page)
  end

  def self.find_for_event(event_id, filter, page)

    conditions = [ " occasions.event_id = ? ", event_id ]
    apply_filter(conditions, filter)

    self.includes(:occasion, group: :school)
        .where(conditions[0], *conditions[1..-1])
        .order("schools.name, groups.name desc")
        .paginate(page: page)
  end

  def self.find_for_occasion(occasion_id, filter, page)
    conditions = [ "occasions.id = ?", occasion_id ]
    apply_filter(conditions, filter)

    self.includes(:occasion, group: :school)
      .where(conditions[0], *conditions[1..-1])
      .order("schools.name, groups.name desc")
      .paginate(page: page)
  end


  def self.bus_booking_csv(bookings)
    CSV.generate(col_sep: "\t") do |csv|

      row = %w(
      Evenemang
      Datum
      Adress
      Område
      Skola
      Grupp
      Medföljande\ vuxen
      Telefonnummer
      E-postadress
      Antal\ platser
      Resa
      Hållplats
      )

      csv << row

      bookings.each do |booking|
        row = [
          booking.occasion.event.name,
          "#{booking.occasion.date} #{I18n.localize(booking.occasion.start_time, format: :only_time)}",
          booking.occasion.address,
          booking.group.school.district.name,
          booking.group.school.name,
          booking.group.name,
          booking.companion_name,
          booking.companion_phone,
          booking.companion_email,
          booking.total_count,
          booking.bus_one_way ? "Enkel resa" : "Tur och retur",
          booking.bus_stop
        ]

        csv << row
      end

    end
  end


  private

  def set_booked_at_timestamp
    self.booked_at = Time.zone.now
  end

  def validate_seats
    return if self.group.blank? || self.occasion.blank?

    total_new = self.total_count
    total_new_wheelchair = self.wheelchair_count

    unless self.new_record?
      total_new -= (self.student_count_was.to_i + self.adult_count_was.to_i + self.wheelchair_count_was.to_i)
      total_new_wheelchair -= self.wheelchair_count_was.to_i
    end

    available_tickets = self.group.available_tickets_by_occasion(self.occasion).to_i

    if self.occasion.single_group && !self.occasion.event.alloted_group?
      available_tickets += self.tickets.deactivated.count
    end

    available_wheelchair_tickets = self.occasion.available_wheelchair_seats

    errors.add(:student_count, "Du måste boka minst 1 plats") if self.total_count <= 0
    errors.add(:student_count, "Du har bara #{available_tickets} platser du kan boka på den här föreställningen") if total_new > available_tickets
    errors.add(:wheelchair_count, "Det finns bara #{available_wheelchair_tickets} rullstolsplatser du kan boka på den här föreställningen") if total_new_wheelchair > available_wheelchair_tickets
  end

  def book_tickets(tickets, type, amount, state = :booked)
    1.upto(amount) do |i|
      return if tickets.blank?

      ticket = tickets.shift

      ticket.state = state
      ticket.group = self.group
      ticket.user = self.user
      ticket.occasion = self.occasion
      ticket.booking = self
      ticket.wheelchair = (type == :wheelchair)
      ticket.adult = (type == :adult)
      ticket.booked_when = Time.zone.now

      ticket.save!
    end
  end

  def self.apply_filter(conditions, filter)
    if !filter.blank? 
      if !filter[:district_id].blank?
        conditions[0] << " and schools.district_id = ? "
        conditions << filter[:district_id]
      end

      if !filter[:unbooked]
        conditions[0] << " and unbooked = ? "
        conditions << false
      end

      if !filter[:search].blank?
        conditions[0] << " and (schools.name ilike ? or groups.name ilike ? or events.name ilike ?) "
        conditions << "%#{filter[:search]}%"
        conditions << "%#{filter[:search]}%"
        conditions << "%#{filter[:search]}%"
      end
    end
  end
end
