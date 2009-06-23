class RoleApplication < ActiveRecord::Base
  PENDING = 0
  ACCEPTED = 1
  DENIED = -1

  belongs_to :role
  belongs_to :group
  belongs_to :user
  belongs_to :culture_provider

  validates_presence_of :message, :message => "Meddelandet får inte vara tomt",
    :if => Proc.new { |application| application.role.is? :booker }
  validate :must_have_culture_provider, :if => Proc.new { |application| application.role.is? :culture_worker }


  protected

  def must_have_culture_provider
    if new_culture_provider_name.blank? && (culture_provider_id.nil? || culture_provider_id.to_i <= 0)
      errors.add :culture_provider_id, "Arrangör måste väljas eller matas in"
    end
  end
end
