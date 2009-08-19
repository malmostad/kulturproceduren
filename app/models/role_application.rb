# A container for role applications in the system.
#
# A user can apply for privileges themselves in the system. The
# application is sent to administrators who can approve or deny
# the application.
class RoleApplication < ActiveRecord::Base

  # Application states
  PENDING = 0
  ACCEPTED = 1
  DENIED = -1

  belongs_to :role
  belongs_to :group
  belongs_to :user
  belongs_to :culture_provider

  validates_presence_of :message,
    :message => "Meddelandet får inte vara tomt",
    :if => Proc.new { |application| application.role.is? :booker }
  validate :must_have_culture_provider,
    :if => Proc.new { |application| application.role.is? :culture_worker }


  protected

  # Validation method for checking that role applications regarding culture worker
  # privileges have a culture provider associated to it.
  def must_have_culture_provider
    if new_culture_provider_name.blank? && (culture_provider_id.nil? || culture_provider_id.to_i <= 0)
      errors.add :culture_provider_id, "Arrangör måste väljas eller matas in"
    end
  end
end
