# Misc migration tasks
namespace :kp do
  namespace :migration do
    desc "Create temporary groups for 6 year olds based on 7 year olds for the new school year"
    task(:create_temporary_groups_for_6_year_olds => :environment) do
      # No pre schools, they already have 6 year olds, and ignore
      # age groups with 3 or less students
      base_groups = Group.find_by_sql "select * from groups where id in (select group_id from age_groups where age = 7 and quantity > 3) and elit_id not like 'forsk%';"

      base_groups.each do |bg|
        temp_group = Group.new do |g|
          g.name = "Temp 6-åringsgrupp - #{bg.name}"
          g.contacts = bg.contacts
          g.elit_id = "temp6-#{bg.elit_id}"
          g.school_id = bg.school_id
          g.active = true
        end

        puts "Processing #{temp_group.name}"

        temp_group.save!

        base_age_group = AgeGroup.first :conditions => { :group_id => bg.id, :age => 7 }

        temp_age = AgeGroup.new do |a|
          a.age = 6
          a.quantity = base_age_group.quantity
          a.group = temp_group
        end

        temp_age.save!
      end
    end

    desc "Generate bookings from existing tickets without bookings"
    task(:generate_bookings_from_tickets => :environment) do
      # Generate bookings from tickets
      Ticket.find_each(
        :conditions => "state > 0" # Only booked tickets
      ) do |ticket|

        booking = Booking.first(
          :conditions => {
            :group_id => ticket.group_id,
            :occasion_id => ticket.occasion_id,
            :user_id => ticket.user_id
          }
        )

        # Create new booking if none existed
        booking ||= Booking.new do |b|
          # Default values
          b.student_count = 0
          b.adult_count = 0
          b.wheelchair_count = 0

          # Associations
          b.group_id = ticket.group_id
          b.occasion_id = ticket.occasion_id
          b.user_id = ticket.user_id

          puts "Creating new booking for #{b.group_id},#{b.occasion_id},#{b.user_id}"

          # Booking timestamp
          b.booked_at = ticket.booked_when

          # Companion
          if ticket.companion
            b.companion_name = ticket.companion.name
            b.companion_phone = ticket.companion.tel_nr
            b.companion_email = ticket.companion.email
          end

          # Booking requirements
          req = BookingRequirement.first(:conditions => { :group_id => ticket.group_id, :occasion_id => ticket.occasion_id })
          b.requirement = req.requirement if req
        end

        # Increase 
        if ticket.wheelchair
          booking.wheelchair_count += 1
        elsif ticket.adult
          booking.adult_count += 1
        else
          booking.student_count += 1
        end

        booking.save!

        ticket.booking_id = booking.id
        ticket.save!
      end
    end
  end
end
