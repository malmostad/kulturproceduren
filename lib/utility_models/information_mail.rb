module UtilityModels
  class InformationMail
    include ::Validatable

    attr_accessor :recipients,
      :subject,
      :body

    validates_presence_of :recipients,
      :message => "En mottagare måste anges"
    validates_true_for :recipients,
      :logic => lambda { [ :all_contacts, :all_users ].include? recipients },
      :message => "Ogiltig mottagare"
    validates_presence_of :subject,
      :message => "Ämnesraden får inte vara tom"
    validates_presence_of :body,
      :message => "Meddelandet får inte vara tomt"

    def initialize(params = {})
      @recipients = params[:recipients].try(:to_sym)
      @subject = params[:subject]
      @body = params[:body]
    end

    def recipients
      @recipients
    end

    def recipient_addresses
      case recipients
      when :all_contacts
        addresses = District.all(:select => :contacts).collect { |m| m.contacts.try(:split, ",") }.compact.flatten
        addresses += School.all(:select => :contacts).collect { |m| m.contacts.try(:split, ",") }.compact.flatten
        addresses += Group.all(:select => :contacts).collect { |m| m.contacts.try(:split, ",") }.compact.flatten
      when :all_users
        addresses = User.all(:select => "email").collect(&:email)
      else
        addresses = []
      end

      return addresses
    end
  end
end
