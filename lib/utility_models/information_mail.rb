module UtilityModels
  class InformationMail
    include ActiveModel::Validations

    attr_accessor :recipients,
      :subject,
      :body,
      :event_id

    attr_reader :event

    validates_presence_of :recipients,
      message: "En mottagare måste anges"
    validate :validate_recipients
    validates_presence_of :subject,
      message: "Ämnesraden får inte vara tom"
    validates_presence_of :body,
      message: "Meddelandet får inte vara tomt"

    def initialize(params = {})
      if params[:recipients]
        @recipients = params[:recipients].to_sym
      else
        @recipients = :all_contacts
      end
      @event = Event.find(params[:event_id]) if params[:event_id]
      @event_id = params[:event_id] if params[:event_id]
      @subject = params[:subject]
      @body = (params[:body] || '').gsub("\r\n", '<br/>').gsub("\r", '<br/>').gsub("\n", '<br/>')
    end

    def recipient_addresses
      addresses = []
      case recipients
      when :all_alloted
        @event.allotments.each do |a|
          case
            when a.for_all?
              District.all.each do |district|
                addresses += (district.contacts || '').split(',')

                district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
                  addresses += (school.contacts || '').split(',')

                  school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
                    addresses += (group.contacts || '').split(',')
                  end
                end
              end

            when a.for_all_with_excluded_districts?
              District.where.not(id: a.excluded_district_ids).each do |district|
                addresses += (district.contacts || '').split(',')

                district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
                  addresses += (school.contacts || '').split(',')

                  school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
                    addresses += (group.contacts || '').split(',')
                  end
                end
              end

            when a.for_district?
              district = District.find_by_id(a.district_id)
              addresses = (district.contacts || '').split(',')

              district.schools.find_by_age_span(event.from_age, event.to_age).each do |school|
                addresses += (school.contacts || '').split(',')

                school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
                  addresses += (group.contacts || '').split(',')
                end
              end

            when a.for_school?
              school = School.find_by_id(a.school_id)
              addresses = (school.contacts || '').split(',')

              school.groups.find_by_age_span(event.from_age, event.to_age).each do |group|
                addresses += (group.contacts || '').split(',')
              end

            when a.for_group?
              group = Group.find_by_id(a.group_id)
              addresses = (group.contacts || '').split(',')

          end
        end

      when :all_contacts
        addresses = District.select(:contacts).collect { |m| m.contacts.try(:split, ",") }.compact.flatten
        addresses += School.select(:contacts).collect { |m| m.contacts.try(:split, ",") }.compact.flatten
        addresses += Group.select(:contacts).collect { |m| m.contacts.try(:split, ",") }.compact.flatten

      when :all_users
        addresses = User.select("email").pluck(:email)

      else
        addresses = @event.booked_users.collect(&:email)
        addresses += @event.bookings.collect(&:companion_email)

      end

      addresses.collect! { |a| a.strip }
      addresses.reject! { |a| a !~ /\S+@\S+/ }
      addresses.uniq!

      return addresses
    end

    private

    def validate_recipients
      unless !recipients.blank? && ([ :all_alloted, :all_booked, :all_contacts, :all_users ].include?(recipients) || Event.exists?(recipients))
        errors.add(:recipients, "Ogiltig mottagare")
      end
    end
  end
end
